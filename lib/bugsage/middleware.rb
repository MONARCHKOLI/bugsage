# frozen_string_literal: true

module Bugsage
  class Middleware
    CASCADE_HEADER = "X-Cascade"

    def initialize(app)
      @app = app
    end

    def call(env)
      return handle_dashboard(env) if dashboard_request?(env)
      return @app.call(env) unless Bugsage.configuration.enabled?

      status, headers, body = @app.call(env)
      close_body(body)

      return pass_through(status, headers, body) if bugsage_response?(body)

      rendered = capture_routing_error(env, headers)
      return rendered if rendered

      rendered = capture_exception(env)
      return rendered if rendered

      [status, headers, body]
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
      path == "/bugsage" || path == "/bugsage/"
    end

    def capture_routing_error(env, headers)
      return unless cascade_pass?(headers)

      exception = routing_error_for(env)
      capture_exception(env, exception)
    end

    def routing_error_for(env)
      if defined?(ActionController::RoutingError)
        ActionController::RoutingError.new(
          "No route matches [#{env['REQUEST_METHOD']}] #{env['PATH_INFO'].inspect}"
        )
      else
        StandardError.new(
          "No route matches [#{env['REQUEST_METHOD']}] #{env['PATH_INFO'].inspect}"
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

    def capture_exception(env, exception = nil)
      config = Bugsage.configuration
      return unless config.enabled?

      if config.show_error_page?
        return ExceptionHandler.render_response(env, exception)
      end

      if config.capture_errors?
        ExceptionHandler.store_exception(env, exception)
        :stored
      end
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
        "Request method" => env["REQUEST_METHOD"],
        "Path" => env["PATH_INFO"],
        "Query string" => env["QUERY_STRING"],
        "Host" => env["HTTP_HOST"] || env["SERVER_NAME"],
        "Request ID" => env["action_dispatch.request_id"] || env["HTTP_X_REQUEST_ID"],
        "Controller" => path_parameter_value(env, "controller"),
        "Action" => path_parameter_value(env, "action"),
        "Path parameters" => path_parameters(env),
        "Request parameters" => request_parameters(env),
        "Query parameters" => query_parameters(env),
        "Form parameters" => form_parameters(env),
        "User agent" => env["HTTP_USER_AGENT"]
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
