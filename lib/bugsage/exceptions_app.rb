# frozen_string_literal: true

module Bugsage
  class ExceptionsApp
    def self.call(env)
      new.call(env)
    end

    def call(env)
      config = Bugsage.configuration

      if config.enabled? && config.show_error_page?
        rendered = ExceptionHandler.render_response(env)
        return rendered if rendered
      elsif config.enabled? && config.capture_errors?
        ExceptionHandler.store_exception(env)
      end

      fallback_response(env)
    end

    private

    def fallback_response(env)
      fallback = Bugsage.configuration.fallback_exceptions_app
      return fallback.call(env) if fallback

      [500, { "Content-Type" => "text/html" }, ["<h1>BugSage could not classify this exception.</h1>"]]
    end
  end
end
