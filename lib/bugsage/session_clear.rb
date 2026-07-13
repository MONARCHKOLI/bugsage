# frozen_string_literal: true

module Bugsage
  class SessionClear
    ENDPOINT = "/bugsage/clear"

    def self.handle_request(env)
      return not_found unless Bugsage.configuration.enabled?

      Store.clear!
      ConsoleContext.clear!
      AiContext.clear!

      redirect_to = "/bugsage"

      if json_request?(env)
        json_response({ ok: true, message: Bugsage.t("errors.session_logs_cleared") })
      else
        redirect_response(redirect_to)
      end
    end

    def self.json_request?(env)
      accept = env["HTTP_ACCEPT"].to_s
      content_type = env["CONTENT_TYPE"].to_s
      accept.include?("application/json") || content_type.include?("application/json")
    end

    def self.json_response(payload)
      [200, { "Content-Type" => "application/json" }, [JSON.generate(payload)]]
    end

    def self.redirect_response(path)
      [302, { "Location" => path, "Content-Type" => "text/plain" }, [Bugsage.t("errors.session_logs_cleared")]]
    end

    def self.not_found
      [404, { "Content-Type" => "text/plain" }, [Bugsage.t("common.not_found")]]
    end
  end
end
