# frozen_string_literal: true

require "json"

module Bugsage
  class AiAnalyzer
    SYSTEM_PROMPT = <<~PROMPT.freeze
      You are BugSage, a Ruby on Rails debugging assistant.
      Refine the provided rule-based analysis using the exception details and request context.
      Respond with JSON only using this schema:
      {
        "root_cause": "string",
        "fixes": ["string", "string"],
        "confidence": 0,
        "notes": "string"
      }
      Keep fixes concrete and actionable. Confidence must be an integer from 0 to 100.
    PROMPT

    def self.enhance(suggestion, exception, context = {}, config: Bugsage.configuration, client: nil)
      new(config: config, client: client).enhance(suggestion, exception, context)
    end

    def initialize(config: Bugsage.configuration, client: nil)
      @config = config
      @client = client
    end

    # Returns [suggestion, ai_error_message]
    def enhance(suggestion, exception, context)
      return [suggestion, nil] unless @config.ai_configured?

      response = client.complete(
        system_prompt: SYSTEM_PROMPT,
        user_prompt: build_prompt(suggestion, exception, context)
      )
      [merge_suggestion(suggestion, parse_response(response)), nil]
    rescue StandardError => e
      log_failure(e)
      [suggestion, e.message]
    end

    private

    def client
      @client ||= @config.ai_client || build_client
    end

    def build_client
      case @config.resolved_ai_provider
      when :cursor
        CursorClient.new(config: @config)
      else
        OpenAiClient.new(config: @config)
      end
    end

    def build_prompt(suggestion, exception, context)
      backtrace = TraceCleaner.clean(exception.backtrace).first(8).join("\n")
      request_context = context.empty? ? "none" : JSON.pretty_generate(context)

      <<~PROMPT
        Exception class: #{exception.class.name}
        Exception message: #{exception.message}
        Location: #{suggestion.location}
        Backtrace:
        #{backtrace}

        Request context:
        #{request_context}

        Rule-based analysis:
        Issue: #{suggestion.issue}
        Root cause: #{suggestion.root_cause}
        Fixes: #{suggestion.fixes.join('; ')}
        Confidence: #{suggestion.confidence}
      PROMPT
    end

    def parse_response(response)
      payload = JSON.parse(extract_json(response))
      {
        root_cause: payload["root_cause"].to_s.strip,
        fixes: Array(payload["fixes"]).map { |fix| fix.to_s.strip }.reject(&:empty?),
        confidence: normalize_confidence(payload["confidence"]),
        notes: payload["notes"].to_s.strip
      }
    end

    def merge_suggestion(suggestion, ai_result)
      return suggestion if ai_result[:fixes].empty? && ai_result[:root_cause].empty?

      suggestion.with_ai_enhancement(
        root_cause: ai_result[:root_cause].empty? ? suggestion.root_cause : ai_result[:root_cause],
        fixes: merge_fixes(suggestion.fixes, ai_result[:fixes]),
        confidence: ai_result[:confidence] || suggestion.confidence,
        ai_notes: ai_result[:notes].empty? ? nil : ai_result[:notes]
      )
    end

    def merge_fixes(rule_fixes, ai_fixes)
      combined = ai_fixes + rule_fixes
      combined.uniq { |fix| fix.downcase }
    end

    def normalize_confidence(value)
      number = Integer(value)
      number.clamp(0, 100)
    rescue ArgumentError, TypeError
      nil
    end

    def extract_json(response)
      stripped = response.to_s.strip
      if stripped.include?("```")
        stripped = stripped.sub(/\A.*?```(?:json)?\s*/im, "").sub(/\s*```.*\z/m, "")
      end

      match = stripped.match(/\{.*\}/m)
      match ? match[0] : stripped
    end

    def log_failure(error)
      message = "[BugSage] AI enhancement failed: #{error.class}: #{error.message}"
      if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
        Rails.logger.warn(message)
      else
        warn(message)
      end
    end
  end
end
