# frozen_string_literal: true

module Bugsage
  module ExceptionHandler
    module_function

    def extract(env, exception = nil)
      ExceptionSupport.extract(env, exception)
    end

    def render_response(env, exception = nil)
      process(env, exception, render: true)
    end

    def store_exception(env, exception = nil)
      process(env, exception, render: false)
    end

    def process(env, exception, render:)
      config = Bugsage.configuration
      return unless config.enabled?

      exception = extract(env, exception)
      return unless exception

      suggestion = Rule.match(exception)
      return unless suggestion

      context = request_context(env)
      ai_error = nil
      if config.ai_configured?
        suggestion, ai_error = AiAnalyzer.enhance(suggestion, exception, context)
      end

      Store.add(suggestion, context, ai_error: ai_error, exception: exception) if config.capture_errors?
      ConsoleContext.set(exception: exception, context: context) if config.show_inline_console?

      return unless render && config.show_error_page?

      [status_for(exception), { "Content-Type" => "text/html" }, [ErrorPage.render(suggestion, context, ai_error: ai_error)]]
    end

    def request_context(env)
      Middleware.new(nil).send(:rails_context, env)
    end

    def status_for(exception)
      if ExceptionSupport.routing_error?(exception) || ExceptionSupport.record_not_found?(exception)
        404
      else
        500
      end
    end

    def bugsage_response?(body)
      content = body.respond_to?(:join) ? body.join : body.to_s
      content.include?("BugSage caught") || content.include?("BugSage Dashboard")
    end
  end
end
