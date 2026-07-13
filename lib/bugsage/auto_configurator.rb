# frozen_string_literal: true

module Bugsage
  module AutoConfigurator
    API_KEY_ENV_VARS = {
      cursor: %w[CURSOR_API_KEY BUGSAGE_CURSOR_API_KEY],
      openai: %w[OPENAI_API_KEY BUGSAGE_OPENAI_API_KEY]
    }.freeze

    module_function

    def apply!(config = Bugsage.configuration, env: ENV)
      apply_environment_settings!(config, env)
      apply_ai_settings!(config, env)
      config
    end

    def apply_environment_settings!(config, env)
      environments = parse_enabled_environments(env["BUGSAGE_ENABLED_ENVIRONMENTS"])
      return if environments.empty?

      config.enabled_environments = environments
    end

    def apply_ai_settings!(config, env)
      return if config.ai_enabled == false

      credentials = detect_api_credentials(env)
      return if credentials.nil?

      config.ai_enabled = true if config.ai_enabled.nil?
      config.ai_provider ||= credentials[:provider]

      assign_api_key!(config, credentials)
    end

    def detect_api_credentials(env = ENV)
      API_KEY_ENV_VARS.each do |provider, names|
        names.each do |name|
          key = env[name].to_s.strip
          next if key.empty?

          return { provider: normalize_provider(key, provider), key: key, source: name }
        end
      end

      nil
    end

    def summary(config = Bugsage.configuration, env: ENV)
      credentials = detect_api_credentials(env)
      environments = Array(config.enabled_environments).map(&:to_s).join(", ")

      lines = [
        "BugSage is ready to use.",
        "Enabled environments: #{environments}",
        "Error page: #{enabled_label(config.show_error_page?('development'))}",
        "Dashboard (/bugsage): #{enabled_label(config.show_dashboard?('development'))}",
        "Inline console: #{enabled_label(config.show_inline_console?('development'))}"
      ]

      if credentials
        lines << "AI provider: #{config.resolved_ai_provider} (from #{credentials[:source]})"
        lines << "AI suggestions: #{enabled_label(config.ai_enabled?('development'))}"
      else
        lines << "AI suggestions: off (set OPENAI_API_KEY or CURSOR_API_KEY to enable)"
      end

      lines
    end

    def enabled_label(value)
      value ? "enabled" : "disabled"
    end

    def parse_enabled_environments(raw)
      return [] if raw.to_s.strip.empty?

      raw.split(",").map { |name| name.strip.downcase.to_sym }.reject(&:empty?)
    end

    def normalize_provider(key, provider)
      return :cursor if key.start_with?("crsr_")

      provider
    end

    def assign_api_key!(config, credentials)
      case credentials[:provider]
      when :cursor
        config.cursor_api_key ||= credentials[:key]
      else
        config.openai_api_key ||= credentials[:key]
      end
    end
  end
end
