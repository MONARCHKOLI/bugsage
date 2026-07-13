# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Bugsage
  class CursorClient
    TERMINAL_STATUSES = %w[FINISHED ERROR CANCELLED EXPIRED].freeze

    def initialize(config: Bugsage.configuration)
      @config = config
    end

    def complete(system_prompt:, user_prompt:)
      agent_id = nil
      agent_id, run_id = create_agent(system_prompt, user_prompt, json_only: true)
      result = poll_run(agent_id, run_id)
      extract_json_content(result)
    ensure
      delete_agent(agent_id) if agent_id
    end

    def chat(system_prompt:, messages:)
      prompt = messages.map { |entry| "#{entry[:role].to_s.capitalize}: #{entry[:content]}" }.join("\n\n")
      agent_id = nil
      agent_id, run_id = create_agent(system_prompt, prompt, json_only: false)
      result = poll_run(agent_id, run_id)
      extract_text_content(result)
    ensure
      delete_agent(agent_id) if agent_id
    end

    private

    def create_agent(system_prompt, user_prompt, json_only: true)
      body = {
        prompt: {
          text: build_agent_prompt(system_prompt, user_prompt, json_only: json_only)
        }
      }
      body[:model] = { id: @config.cursor_model } if @config.cursor_model.to_s.strip != ""

      response = request(
        method: :post,
        path: "/v1/agents",
        body: body
      )

      agent_id = response.dig("agent", "id")
      run_id = response.dig("run", "id")
      if agent_id.to_s.empty? || run_id.to_s.empty?
        raise Error,
              "Cursor agent response did not include agent and run ids"
      end

      [agent_id, run_id]
    end

    def poll_run(agent_id, run_id)
      deadline = Time.now + @config.effective_ai_timeout
      sleep_interval = 1.0

      loop do
        run = request(method: :get, path: "/v1/agents/#{agent_id}/runs/#{run_id}")
        status = run["status"].to_s

        if status == "FINISHED"
          result = run["result"].to_s
          raise Error, "Cursor run finished without a result" if result.strip.empty?

          return result
        end

        raise Error, "Cursor run ended with status #{status}" if TERMINAL_STATUSES.include?(status)

        raise Error, "Cursor run timed out after #{@config.effective_ai_timeout}s" if Time.now >= deadline

        sleep(sleep_interval)
        sleep_interval = [sleep_interval * 1.5, 5.0].min
      end
    end

    def delete_agent(agent_id)
      request(method: :delete, path: "/v1/agents/#{agent_id}")
    rescue StandardError
      nil
    end

    def build_agent_prompt(system_prompt, user_prompt, json_only: true)
      reply_instruction = if json_only
                            "Reply with JSON only. Do not create files, run shell commands, or modify a repository."
                          else
                            "Reply in plain text. Do not create files, run shell commands, or modify a repository."
                          end

      <<~PROMPT
        #{system_prompt}

        #{user_prompt}

        #{reply_instruction}
      PROMPT
    end

    def extract_json_content(text)
      stripped = text.to_s.strip
      stripped = stripped.sub(/\A.*?```(?:json)?\s*/im, "").sub(/\s*```.*\z/m, "") if stripped.include?("```")

      match = stripped.match(/\{.*\}/m)
      match ? match[0] : stripped
    end

    def extract_text_content(text)
      stripped = text.to_s.strip
      stripped = stripped.sub(/\A```(?:\w*)\s*/m, "").sub(/\s*```\z/m, "") if stripped.start_with?("```")
      stripped
    end

    def request(method:, path:, body: nil)
      uri = URI.join(api_base, path.sub(%r{\A/}, ""))
      request_class = {
        get: Net::HTTP::Get,
        post: Net::HTTP::Post,
        delete: Net::HTTP::Delete
      }.fetch(method)

      http_request = request_class.new(uri)
      http_request["Authorization"] = "Bearer #{@config.resolved_cursor_api_key}"
      http_request["Content-Type"] = "application/json"
      http_request.body = JSON.generate(body) if body

      response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: @config.ai_timeout,
        read_timeout: @config.ai_timeout
      ) do |http|
        http.request(http_request)
      end

      raise Error, error_message_for(response) unless response.is_a?(Net::HTTPSuccess)

      return {} if response.body.to_s.strip.empty?

      JSON.parse(response.body)
    end

    def api_base
      base = @config.cursor_api_base.to_s
      base.end_with?("/") ? base : "#{base}/"
    end

    def error_message_for(response)
      body = JSON.parse(response.body)
      detail = body["message"] || body.dig("error", "message") || body["error"]
      message = "Cursor request failed with status #{response.code}"
      message += ": #{detail}" if detail
      message
    rescue JSON::ParserError
      "Cursor request failed with status #{response.code}"
    end
  end
end
