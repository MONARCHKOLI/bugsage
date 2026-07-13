# frozen_string_literal: true

require "yaml"

module Bugsage
  module Translations
    LOCALE_DIR = File.expand_path("locales", __dir__)

    module_function

    def load!
      return if @loaded

      paths = Dir[File.join(LOCALE_DIR, "*.yml")]
      if defined?(::I18n)
        ::I18n.load_path |= paths
      else
        @fallback_translations = {}
        paths.each do |path|
          data = YAML.safe_load_file(path, aliases: true)
          deep_merge!(@fallback_translations, data)
        end
      end

      @loaded = true
    end

    def t(key, **)
      load!
      full_key = key.to_s.start_with?("bugsage.") ? key : "bugsage.#{key}"

      if defined?(::I18n)
        ::I18n.t(full_key, **)
      else
        translate_fallback(full_key, **)
      end
    end

    def translate_fallback(key, **options)
      keys = key.split(".")
      value = dig_fallback(keys)
      return options[:default] if value.nil? && options.key?(:default)

      case value
      when Array
        value
      when String
        interpolate(value, options)
      else
        options.fetch(:default, missing_translation(key))
      end
    end

    def dig_fallback(keys)
      locale = @fallback_translations["en"] || @fallback_translations[:en] || {}
      keys.reduce(locale) do |node, segment|
        break nil unless node.is_a?(Hash)

        node[segment] || node[segment.to_sym]
      end
    end

    def deep_merge!(base, other)
      other.each do |key, value|
        key = key.to_s
        if base[key].is_a?(Hash) && value.is_a?(Hash)
          deep_merge!(base[key], value)
        else
          base[key] = value
        end
      end
    end

    def interpolate(string, options)
      string.gsub(/%\{(\w+)\}/) do
        symbol = Regexp.last_match(1).to_sym
        options.key?(symbol) ? options[symbol].to_s : "%{#{symbol}}"
      end
    end

    def missing_translation(key)
      key
    end
  end
end
