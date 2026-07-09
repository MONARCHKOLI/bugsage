# frozen_string_literal: true

module Bugsage
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      return render_dashboard if env["PATH_INFO"] == "/bugsage"

      @app.call(env)
    rescue StandardError => e
      suggestion = Rule.match(e)

      if suggestion
        context = rails_context(env)
        Store.add(suggestion, context)
        render_error_page(suggestion, context)
      elsif env["action_dispatch.exception"]
        ExceptionsApp.new.call(env)
      else
        raise e
      end
    end

    private

    def render_dashboard
      [200, { "Content-Type" => "text/html" }, [Dashboard.render(Store.all)]]
    end

    def render_error_page(suggestion, context = {})
      [500, { "Content-Type" => "text/html" }, [ErrorPage.render(suggestion, context)]]
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
