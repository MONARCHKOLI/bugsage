# frozen_string_literal: true

module Bugsage
  # Shared helpers for AI provider responses.
  module AiSupport
    class << self
      def extract_json(response)
        stripped = response.to_s.strip
        stripped = stripped.sub(/\A.*?```(?:json)?\s*/im, "").sub(/\s*```.*\z/m, "") if stripped.include?("```")

        match = stripped.match(/\{.*\}/m)
        match ? match[0] : stripped
      end

      def log_failure(label, error)
        message = "[BugSage] #{label}: #{error.class}: #{error.message}"
        if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
          Rails.logger.warn(message)
        else
          warn(message)
        end
      end

      def build_client(config = Bugsage.configuration)
        return config.ai_client if config.ai_client

        case config.resolved_ai_provider
        when :cursor
          CursorClient.new(config: config)
        else
          OpenAiClient.new(config: config)
        end
      end
    end
  end
end
