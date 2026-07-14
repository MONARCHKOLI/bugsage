# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Bugsage
  class OpenAiClient
    def initialize(config: Bugsage.configuration)
      @config = config
    end

    def complete(system_prompt:, user_prompt:)
      post_chat(
        temperature: 0.2,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: user_prompt }
        ]
      )
    end

    def chat(system_prompt:, messages:)
      post_chat(
        temperature: 0.3,
        messages: [{ role: "system", content: system_prompt }] + messages
      )
    end

    def http_request(uri, request)
      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: @config.ai_timeout,
        read_timeout: @config.ai_timeout
      ) do |http|
        http.request(request)
      end
    end

    private

    def post_chat(messages:, temperature:, response_format: nil)
      validate_api_key!

      uri = URI.join(api_base, "chat/completions")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@config.resolved_openai_api_key}"
      request["Content-Type"] = "application/json"

      body = {
        model: @config.openai_model,
        temperature: temperature,
        messages: messages
      }
      body[:response_format] = response_format if response_format
      request.body = JSON.generate(body)

      response = http_request(uri, request)
      raise Error, error_message_for(response) unless response.is_a?(Net::HTTPSuccess)

      payload = JSON.parse(response.body)
      content = payload.dig("choices", 0, "message", "content")
      raise Error, "OpenAI response did not include message content" if content.to_s.strip.empty?

      content
    end

    def api_base
      base = @config.openai_api_base.to_s
      base.end_with?("/") ? base : "#{base}/"
    end

    def validate_api_key!
      key = @config.resolved_openai_api_key.to_s
      return if key.strip.empty?

      return unless key.start_with?("crsr_")

      raise Error,
            "A Cursor API key was provided, but the OpenAI provider is selected. " \
            "Set config.bugsage.ai_provider = :cursor or use CURSOR_API_KEY."
    end

    def error_message_for(response)
      body = JSON.parse(response.body)
      detail = body.dig("error", "message") || body["message"]
      hint = case response.code.to_i
             when 401 then "Check that OPENAI_API_KEY is valid."
             when 429 then "Rate limit or billing quota exceeded. Check usage at platform.openai.com."
             end

      message = "OpenAI request failed with status #{response.code}"
      message += ": #{detail}" if detail
      message += " #{hint}" if hint
      message
    rescue JSON::ParserError
      "OpenAI request failed with status #{response.code}"
    end
  end
end
