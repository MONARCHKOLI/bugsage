# frozen_string_literal: true

module Bugsage
  class Middleware
    CASCADE_HEADER = "X-Cascade"

    def initialize(app)
      @app = app
    end

    def call(env)
      return handle_dashboard(env) if dashboard_request?(env)
      return InlineConsole.handle_request(env) if console_request?(env)
      return AiPanel.handle_request(env) if ai_suggest_request?(env)
      return AiChat.handle_request(env) if ai_chat_request?(env)
      return FixApplicator.handle_request(env) if apply_fix_request?(env)
      return SessionClear.handle_request(env) if clear_request?(env)
      return @app.call(env) unless Bugsage.configuration.enabled?

      status, headers, body = @app.call(env)
      body_parts = extract_body(body)
      close_body(body)

      return pass_through(status, headers, body_parts) if bugsage_response?(body_parts)

      rendered = capture_routing_error(env, headers)
      return rendered if rendered

      rendered = capture_exception(env)
      return rendered if rendered

      capture_http_error(env, status, body_parts.join)
      pass_through(status, headers, body_parts)
    rescue StandardError => e
      result = capture_exception(env, e)
      return result if result.is_a?(Array)

      raise e
    end

    private

    def handle_dashboard(env)
      if Bugsage.configuration.show_dashboard?
        render_dashboard
      else
        @app.call(env)
      end
    end

    def dashboard_request?(env)
      path = env["PATH_INFO"].to_s
      ["/bugsage", "/bugsage/"].include?(path)
    end

    def console_request?(env)
      env["REQUEST_METHOD"] == "POST" && env["PATH_INFO"] == "/bugsage/console"
    end

    def ai_suggest_request?(env)
      env["REQUEST_METHOD"] == "POST" && env["PATH_INFO"] == AiPanel::ENDPOINT
    end

    def ai_chat_request?(env)
      env["REQUEST_METHOD"] == "POST" && env["PATH_INFO"] == AiChat::ENDPOINT
    end

    def apply_fix_request?(env)
      env["REQUEST_METHOD"] == "POST" && env["PATH_INFO"] == FixApplicator::ENDPOINT
    end

    def clear_request?(env)
      env["REQUEST_METHOD"] == "POST" && env["PATH_INFO"] == SessionClear::ENDPOINT
    end

    def capture_routing_error(env, headers)
      return unless cascade_pass?(headers)

      exception = routing_error_for(env)
      capture_exception(env, exception)
    end

    def routing_error_for(env)
      if defined?(ActionController::RoutingError)
        ActionController::RoutingError.new(
          "No route matches [#{env["REQUEST_METHOD"]}] #{env["PATH_INFO"].inspect}"
        )
      else
        StandardError.new(
          "No route matches [#{env["REQUEST_METHOD"]}] #{env["PATH_INFO"].inspect}"
        )
      end
    end

    def cascade_pass?(headers)
      headers[CASCADE_HEADER] == "pass" ||
        (defined?(ActionDispatch::Constants) && headers[ActionDispatch::Constants::X_CASCADE] == "pass")
    end

    def close_body(body)
      body.close if body.respond_to?(:close)
    end

    def extract_body(body)
      return Array(body) unless body.respond_to?(:each)

      parts = []
      body.each { |part| parts << part }
      parts
    end

    def capture_http_error(env, status, body)
      config = Bugsage.configuration
      return unless config.capture_http_errors?
      return unless HttpErrorCapture.capture?(status, env)

      ExceptionHandler.store_http_error(env, status, body)
    end

    def capture_exception(env, exception = nil)
      config = Bugsage.configuration
      return unless config.enabled?

      candidate = exception || ExceptionSupport.extract(env)
      return unless candidate

      return ExceptionHandler.render_response(env, candidate) if config.show_error_page?

      return unless config.capture_errors?

      ExceptionHandler.store_exception(env, candidate)
      :stored
    end

    def bugsage_response?(body)
      ExceptionHandler.bugsage_response?(body)
    end

    def pass_through(status, headers, body)
      [status, headers, body]
    end

    def render_dashboard
      [200, { "Content-Type" => "text/html" }, [Dashboard.render(Store.all)]]
    end

    def rails_context(env)
      return {} unless env.is_a?(Hash)

      {
        Bugsage.t("context.request_method") => env["REQUEST_METHOD"],
        Bugsage.t("context.path") => env["PATH_INFO"],
        Bugsage.t("context.query_string") => env["QUERY_STRING"],
        Bugsage.t("context.host") => env["HTTP_HOST"] || env["SERVER_NAME"],
        Bugsage.t("context.request_id") => env["action_dispatch.request_id"] || env["HTTP_X_REQUEST_ID"],
        Bugsage.t("context.controller") => path_parameter_value(env, "controller"),
        Bugsage.t("context.action") => path_parameter_value(env, "action"),
        Bugsage.t("context.path_parameters") => path_parameters(env),
        Bugsage.t("context.request_parameters") => request_parameters(env),
        Bugsage.t("context.query_parameters") => query_parameters(env),
        Bugsage.t("context.form_parameters") => form_parameters(env),
        Bugsage.t("context.user_agent") => env["HTTP_USER_AGENT"]
      }.compact.reject { |_, value| blank?(value) }
    end

    def path_parameter_value(env, key)
      params = path_parameters(env)
      return nil unless params.is_a?(Hash)

      params[key.to_s] || params[key.to_sym]
    end

    def path_parameters(env)
      env["action_dispatch.request.path_parameters"]
    end

    def request_parameters(env)
      env["action_dispatch.request.parameters"]
    end

    def query_parameters(env)
      env["action_dispatch.request.query_parameters"]
    end

    def form_parameters(env)
      env["action_dispatch.request.form_parameters"]
    end

    def blank?(value)
      value.respond_to?(:empty?) ? value.empty? : value.nil? || value == ""
    end
  end
end
