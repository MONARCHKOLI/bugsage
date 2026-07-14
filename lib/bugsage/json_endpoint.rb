# frozen_string_literal: true

require "json"

module Bugsage
  # Shared Rack JSON helpers for BugSage HTTP endpoints.
  # Extend on endpoint classes: `extend JsonEndpoint`
  module JsonEndpoint
    def parse_request_body(env)
      body = env["rack.input"]
      raw = body.respond_to?(:read) ? body.read : body.to_s
      body.rewind if body.respond_to?(:rewind)

      return {} if raw.to_s.strip.empty?

      JSON.parse(raw)
    rescue JSON::ParserError
      {}
    end

    def json_response(payload = nil, status: 200, **attrs)
      body = payload.nil? ? attrs : payload
      [status, { "Content-Type" => "application/json" }, [JSON.generate(body)]]
    end

    def error_response(message)
      { ok: false, error: message.to_s }
    end

    def not_found
      [404, { "Content-Type" => "text/plain" }, [Bugsage.t("common.not_found")]]
    end
  end
end
