# frozen_string_literal: true

module Bugsage
  # Builds a labeled Rails request context hash from a Rack env.
  module RequestContext
    class << self
      def from_env(env)
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

      private

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
end
