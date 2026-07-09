# frozen_string_literal: true

module Bugsage
  class Configuration
    attr_accessor :enabled_environments,
                  :show_error_page,
                  :show_dashboard,
                  :capture_errors,
                  :ai_enabled,
                  :openai_api_key,
                  :openai_model,
                  :openai_api_base,
                  :ai_timeout,
                  :ai_client,
                  :fallback_exceptions_app

    def initialize
      @enabled_environments = %i[development test]
      @show_error_page = nil
      @show_dashboard = nil
      @capture_errors = true
      @ai_enabled = false
      @openai_api_key = nil
      @openai_model = "gpt-4o-mini"
      @openai_api_base = "https://api.openai.com/v1"
      @ai_timeout = 15
      @ai_client = nil
      @fallback_exceptions_app = nil
    end

    def enabled?(environment = current_environment)
      environment_names.include?(environment.to_s)
    end

    def show_error_page?(environment = current_environment)
      return show_error_page unless show_error_page.nil?

      environment.to_s == "development"
    end

    def show_dashboard?(environment = current_environment)
      return show_dashboard unless show_dashboard.nil?

      environment.to_s == "development"
    end

    def capture_errors?(environment = current_environment)
      return false unless enabled?(environment)

      capture_errors
    end

    def ai_enabled?(environment = current_environment)
      return false unless enabled?(environment)

      ai_enabled
    end

    def ai_configured?(environment = current_environment)
      return false unless ai_enabled?(environment)

      !ai_client.nil? || !resolved_openai_api_key.to_s.strip.empty?
    end

    def resolved_openai_api_key
      openai_api_key || ENV["OPENAI_API_KEY"] || ENV["BUGSAGE_OPENAI_API_KEY"]
    end

    def current_environment
      if defined?(Rails) && Rails.respond_to?(:env)
        Rails.env.to_s
      else
        ENV.fetch("RAILS_ENV", ENV.fetch("RACK_ENV", "development"))
      end
    end

    private

    def environment_names
      Array(enabled_environments).map(&:to_s)
    end
  end
end
