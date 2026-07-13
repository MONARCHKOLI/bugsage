# frozen_string_literal: true

require "json"

module Bugsage
  class AiChat
    ENDPOINT = "/bugsage/ai-chat"

    SYSTEM_PROMPT = <<~PROMPT
      You are BugSage, a Ruby on Rails debugging assistant chatting with a developer
      about a specific caught exception.

      Respond with JSON only using this schema:
      {
        "reply": "conversational answer shown in chat",
        "code_patch": null | {
          "action": "replace_lines | delete_lines | insert_before | no_change",
          "start_line": 0,
          "end_line": 0,
          "replacement": "string"
        }
      }

      Rules:
      - reply must explain your answer clearly and concisely.
      - Include code_patch ONLY when the developer asks for a code change, asks to
        revise the current suggested fix, or agrees to an alternative approach
        (for example commenting out a line instead of deleting it).
      - When they want to comment out a line, use replace_lines with the commented
        Ruby code in replacement (e.g. "# raise "debug""), not delete_lines.
      - Use absolute line numbers from the numbered source (the line marked with >>).
      - NEVER duplicate code that already exists in the file.
      - Change ONLY the lines required for the requested fix.
      - Set code_patch to null when answering questions without changing the fix.
      - replacement must be only the new Ruby code for affected lines, without markdown fences.
    PROMPT

    def self.handle_request(env)
      return not_found unless Bugsage.configuration.ai_configured?

      payload = parse_request_body(env)
      context = AiPanel.load_context(payload)
      return json_response(error_response(Bugsage.t("errors.ai_context_not_available"))) unless context

      message = payload["message"].to_s.strip
      return json_response(error_response(Bugsage.t("errors.enter_message"))) if message.empty?

      history = normalize_history(payload["history"])
      result = chat(context, message, history)

      updated_history = history + [
        { "role" => "user", "content" => message },
        { "role" => "assistant", "content" => result[:reply] }
      ]

      persist_chat_patch!(context, result[:code_patch], payload["index"]) if result[:code_patch]

      json_response(
        ok: true,
        reply: result[:reply],
        history: updated_history,
        code_patch: result[:code_patch],
        code_fix: result[:code_fix]
      )
    rescue StandardError => e
      log_failure(e)
      json_response(error_response(e.message))
    end

    def self.chat(context, message, history)
      client = build_client
      user_prompt = build_chat_prompt(context, message, history)
      response = client.complete(system_prompt: SYSTEM_PROMPT, user_prompt: user_prompt)
      parse_chat_response(response, context[:suggestion])
    end

    def self.build_chat_prompt(context, message, history)
      context_block = build_context_block(context)
      conversation = history.map do |entry|
        "#{entry["role"].capitalize}: #{entry["content"]}"
      end.join("\n\n")

      parts = [context_block]
      parts << "Conversation so far:\n#{conversation}" unless conversation.empty?
      parts << "Developer: #{message}"
      parts.join("\n\n")
    end

    def self.parse_chat_response(response, suggestion)
      payload = JSON.parse(extract_json(response))
      _file_path, line_number = CodeContext.extract_location(suggestion.location)
      code_patch = parse_code_patch(payload, line_number)

      reply = payload["reply"].to_s.strip
      reply = payload["notes"].to_s.strip if reply.empty?

      {
        reply: reply.empty? ? Bugsage.t("errors.default_chat_reply") : reply,
        code_patch: code_patch,
        code_fix: CodePatch.preview_for(code_patch)
      }
    end

    def self.parse_code_patch(payload, line_number)
      patch_data = payload["code_patch"]
      return nil if patch_data.nil? || (patch_data.respond_to?(:empty?) && patch_data.empty?)

      patch = CodePatch.from_ai(payload, error_line: line_number || 1)
      patch&.to_h
    end

    def self.persist_chat_patch!(context, code_patch, index)
      return unless code_patch.is_a?(Hash) && !code_patch.empty?

      suggestion = context[:suggestion]
      updated = suggestion.with_ai_enhancement(
        root_cause: suggestion.root_cause,
        fixes: suggestion.fixes,
        confidence: suggestion.confidence,
        ai_notes: suggestion.ai_notes,
        code_patch: code_patch
      )

      if index
        Store.update_at(index.to_i, updated)
      elsif Store.all.any?
        Store.update_at(0, updated)
      end
    end

    def self.build_context_block(context, source_context = nil)
      suggestion = context[:suggestion]
      exception = context[:exception]
      file_path, line_number = CodeContext.extract_location(suggestion.location)
      source_context ||= CodeContext.numbered_source(file_path, line_number) if file_path && line_number
      source_block = source_context ? source_context[:source] : "unavailable"
      patch_json = suggestion.code_patch ? JSON.generate(suggestion.code_patch) : "none"

      <<~PROMPT
        Exception: #{exception.class.name}
        Message: #{exception.message}
        Location: #{suggestion.location}
        Root cause: #{suggestion.root_cause}
        Suggested fixes: #{suggestion.fixes.join("; ")}
        AI notes: #{suggestion.ai_notes}
        Current code_patch JSON: #{patch_json}
        Current patch preview: #{suggestion.code_fix || "none yet"}

        Numbered source:
        #{source_block}
      PROMPT
    end

    def self.extract_json(response)
      stripped = response.to_s.strip
      stripped = stripped.sub(/\A.*?```(?:json)?\s*/im, "").sub(/\s*```.*\z/m, "") if stripped.include?("```")

      match = stripped.match(/\{.*\}/m)
      match ? match[0] : stripped
    end

    def self.build_client
      config = Bugsage.configuration
      return config.ai_client if config.ai_client

      case config.resolved_ai_provider
      when :cursor
        CursorClient.new(config: config)
      else
        OpenAiClient.new(config: config)
      end
    end

    def self.normalize_history(history)
      Array(history).filter_map do |entry|
        role = entry["role"].to_s
        content = entry["content"].to_s.strip
        next if content.empty?
        next unless %w[user assistant].include?(role)

        { "role" => role, "content" => content }
      end
    end

    def self.render_widget(suffix:, bug_index: nil)
      index_attr = bug_index.nil? ? "" : %( data-bug-index="#{bug_index}")

      <<~HTML
        <div class="ai-loading-overlay hidden" id="bugsage-ai-loading#{suffix}" aria-hidden="true">
          <div class="ai-loading-card">
            <div class="ai-spinner" aria-hidden="true"></div>
            <p class="ai-loading-title">#{CodeContext.escape_html(Bugsage.t("ui.ai_chat.working_title"))}</p>
            <p class="ai-loading-step" id="bugsage-ai-loading-step#{suffix}">#{CodeContext.escape_html(Bugsage.t("ui.ai_chat.reading_source"))}</p>
            <div class="ai-loading-bar"><span class="ai-loading-bar-fill"></span></div>
          </div>
        </div>

        <div class="ai-chat-panel hidden" id="bugsage-ai-chat#{suffix}"#{index_attr}>
          <div class="ai-chat-header">
            <span>#{CodeContext.escape_html(Bugsage.t("ui.ai_chat.chat_header"))}</span>
            <button type="button" class="ai-chat-close" aria-label="#{CodeContext.escape_html(Bugsage.t("ui.ai_chat.close_chat_aria"))}">&times;</button>
          </div>
          <div class="ai-chat-messages" id="bugsage-ai-chat-messages#{suffix}" aria-live="polite"></div>
          <form class="ai-chat-form bugsage-ai-chat-form" data-output-target="#bugsage-ai-chat-messages#{suffix}">
            <input
              class="ai-chat-input"
              type="text"
              name="message"
              autocomplete="off"
              placeholder="#{CodeContext.escape_html(Bugsage.t("ui.ai_chat.input_placeholder"))}"
            />
            <button type="submit" class="ai-chat-send">#{CodeContext.escape_html(Bugsage.t("ui.ai_chat.send"))}</button>
          </form>
        </div>
      HTML
    end

    def self.styles
      <<~CSS
        .ai-panel.is-loading {
          overflow: hidden;
        }
        .ai-panel-header-actions {
          display: inline-flex;
          align-items: center;
          gap: 8px;
        }
        .ai-chat-toggle {
          background: rgba(137, 180, 250, 0.15);
          color: #89b4fa;
          border: 1px solid rgba(137, 180, 250, 0.35);
          border-radius: 999px;
          width: 36px;
          height: 36px;
          font-size: 16px;
          cursor: pointer;
        }
        .ai-chat-toggle:hover {
          background: rgba(137, 180, 250, 0.25);
        }
        .ai-loading-overlay {
          position: absolute;
          inset: 0;
          background: rgba(30, 30, 46, 0.82);
          border-radius: 8px;
          display: flex;
          align-items: center;
          justify-content: center;
          z-index: 2;
        }
        .ai-loading-overlay.hidden {
          display: none;
        }
        .ai-loading-card {
          text-align: center;
          padding: 20px;
          width: min(100%, 280px);
        }
        .ai-spinner {
          width: 42px;
          height: 42px;
          border: 3px solid rgba(137, 180, 250, 0.2);
          border-top-color: #89b4fa;
          border-radius: 50%;
          margin: 0 auto 14px;
          animation: bugsage-spin 0.9s linear infinite;
        }
        .ai-loading-title {
          color: #cdd6f4;
          font-size: 14px;
          font-weight: bold;
          margin: 0 0 6px 0;
        }
        .ai-loading-step {
          color: #f9e2af;
          font-size: 12px;
          margin: 0 0 12px 0;
          min-height: 16px;
        }
        .ai-loading-bar {
          height: 4px;
          background: rgba(137, 180, 250, 0.15);
          border-radius: 999px;
          overflow: hidden;
        }
        .ai-loading-bar-fill {
          display: block;
          height: 100%;
          width: 35%;
          background: linear-gradient(90deg, #89b4fa, #a6e3a1);
          border-radius: 999px;
          animation: bugsage-progress 1.4s ease-in-out infinite;
        }
        @keyframes bugsage-spin {
          to { transform: rotate(360deg); }
        }
        @keyframes bugsage-progress {
          0% { transform: translateX(-120%); }
          100% { transform: translateX(320%); }
        }
        .ai-chat-panel {
          margin-top: 14px;
          background: #1e1e2e;
          border: 1px solid #45475a;
          border-radius: 8px;
          overflow: hidden;
        }
        .ai-chat-panel.hidden {
          display: none;
        }
        .ai-chat-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 10px 12px;
          background: #313244;
          color: #cdd6f4;
          font-size: 13px;
          font-weight: bold;
        }
        .ai-chat-close {
          background: transparent;
          border: 0;
          color: #a6adc8;
          font-size: 20px;
          cursor: pointer;
          line-height: 1;
        }
        .ai-chat-messages {
          max-height: 220px;
          overflow-y: auto;
          padding: 12px;
          display: flex;
          flex-direction: column;
          gap: 10px;
        }
        .ai-chat-bubble {
          max-width: 92%;
          padding: 10px 12px;
          border-radius: 10px;
          font-size: 13px;
          line-height: 1.45;
          white-space: pre-wrap;
        }
        .ai-chat-bubble.user {
          align-self: flex-end;
          background: rgba(137, 180, 250, 0.18);
          color: #cdd6f4;
        }
        .ai-chat-bubble.assistant {
          align-self: flex-start;
          background: rgba(166, 227, 161, 0.12);
          color: #cdd6f4;
        }
        .ai-chat-bubble.loading {
          align-self: flex-start;
          color: #f9e2af;
          font-style: italic;
        }
        .ai-chat-form {
          display: flex;
          gap: 8px;
          padding: 12px;
          border-top: 1px solid #45475a;
        }
        .ai-chat-input {
          flex: 1;
          background: #313244;
          color: #cdd6f4;
          border: 1px solid #45475a;
          border-radius: 6px;
          padding: 10px 12px;
          font-family: inherit;
          font-size: 13px;
        }
        .ai-chat-send {
          background: #89b4fa;
          color: #1e1e2e;
          border: 0;
          border-radius: 6px;
          padding: 10px 14px;
          font-family: inherit;
          font-size: 13px;
          font-weight: bold;
          cursor: pointer;
        }
        .ai-chat-send:disabled {
          opacity: 0.5;
          cursor: not-allowed;
        }
      CSS
    end

    def self.log_failure(error)
      message = "[BugSage] AI chat failed: #{error.class}: #{error.message}"
      if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
        Rails.logger.warn(message)
      else
        warn(message)
      end
    end

    def self.error_response(message)
      { ok: false, error: message.to_s }
    end

    def self.parse_request_body(env)
      body = env["rack.input"]
      raw = body.respond_to?(:read) ? body.read : body.to_s
      body.rewind if body.respond_to?(:rewind)

      return {} if raw.to_s.strip.empty?

      JSON.parse(raw)
    rescue JSON::ParserError
      {}
    end

    def self.json_response(payload)
      [200, { "Content-Type" => "application/json" }, [JSON.generate(payload)]]
    end

    def self.not_found
      [404, { "Content-Type" => "text/plain" }, [Bugsage.t("common.not_found")]]
    end
  end
end
