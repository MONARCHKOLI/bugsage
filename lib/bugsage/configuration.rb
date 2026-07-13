# frozen_string_literal: true

module Bugsage
  class Configuration
    AI_PROVIDERS = %i[openai cursor].freeze

    attr_accessor :enabled_environments,
                  :show_error_page,
                  :show_dashboard,
                  :show_inline_console,
                  :capture_errors,
                  :capture_http_errors,
                  :ai_enabled,
                  :ai_provider,
                  :openai_api_key,
                  :openai_model,
                  :openai_api_base,
                  :cursor_api_key,
                  :cursor_model,
                  :cursor_api_base,
                  :ai_timeout,
                  :ai_client,
                  :fallback_exceptions_app

    def initialize
      @enabled_environments = %i[development test]
      @show_error_page = nil
      @show_dashboard = nil
      @show_inline_console = nil
      @capture_errors = true
      @capture_http_errors = true
      @ai_enabled = nil
      @ai_provider = nil
      @openai_api_key = nil
      @openai_model = "gpt-4o-mini"
      @openai_api_base = "https://api.openai.com/v1"
      @cursor_api_key = nil
      @cursor_model = nil
      @cursor_api_base = "https://api.cursor.com"
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

    def show_inline_console?(environment = current_environment)
      return show_inline_console unless show_inline_console.nil?

      environment.to_s == "development"
    end

    def capture_errors?(environment = current_environment)
      return false unless enabled?(environment)

      capture_errors
    end

    def capture_http_errors?(environment = current_environment)
      return false unless capture_errors?(environment)

      capture_http_errors != false
    end

    def ai_enabled?(environment = current_environment)
      return false unless enabled?(environment)
      return ai_enabled unless ai_enabled.nil?

      credential_available?
    end

    def credential_available?
      !resolved_openai_api_key.to_s.strip.empty? || !resolved_cursor_api_key.to_s.strip.empty?
    end

    def ai_configured?(environment = current_environment)
      return false unless ai_enabled?(environment)

      return true unless ai_client.nil?

      case resolved_ai_provider
      when :cursor
        !resolved_cursor_api_key.to_s.strip.empty?
      else
        !resolved_openai_api_key.to_s.strip.empty?
      end
    end

    def resolved_ai_provider
      provider = ai_provider&.to_sym
      return provider if provider && AI_PROVIDERS.include?(provider)

      return :cursor if resolved_cursor_api_key.to_s.start_with?("crsr_")

      :openai
    end

    def resolved_openai_api_key
      key = openai_api_key || ENV["OPENAI_API_KEY"] || ENV.fetch("BUGSAGE_OPENAI_API_KEY", nil)
      return nil if key.to_s.start_with?("crsr_")

      key
    end

    def resolved_cursor_api_key
      explicit = cursor_api_key || ENV["CURSOR_API_KEY"] || ENV.fetch("BUGSAGE_CURSOR_API_KEY", nil)
      return explicit if explicit.to_s.start_with?("crsr_")

      misrouted = openai_api_key || ENV["OPENAI_API_KEY"] || ENV.fetch("BUGSAGE_OPENAI_API_KEY", nil)
      return misrouted if misrouted.to_s.start_with?("crsr_")

      explicit
    end

    def effective_ai_timeout
      return [ai_timeout, 90].max if resolved_ai_provider == :cursor

      ai_timeout
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
