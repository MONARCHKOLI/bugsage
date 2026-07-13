# frozen_string_literal: true

require_relative "bugsage/version"
require_relative "bugsage/configuration"
require_relative "bugsage/suggestion"
require_relative "bugsage/trace_cleaner"
require_relative "bugsage/exception_support"
require_relative "bugsage/http_response_error"
require_relative "bugsage/http_error_capture"
require_relative "bugsage/code_context"
require_relative "bugsage/rule"
require_relative "bugsage/openai_client"
require_relative "bugsage/cursor_client"
require_relative "bugsage/ai_analyzer"
require_relative "bugsage/formatter"
require_relative "bugsage/store"
require_relative "bugsage/console_context"
require_relative "bugsage/ai_context"
require_relative "bugsage/inline_console"
require_relative "bugsage/ai_panel"
require_relative "bugsage/ai_chat"
require_relative "bugsage/code_patch"
require_relative "bugsage/editor_links"
require_relative "bugsage/fix_applicator"
require_relative "bugsage/session_clear"
require_relative "bugsage/page_actions"
require_relative "bugsage/translations"
require_relative "bugsage/exception_handler"
require_relative "bugsage/error_page"
require_relative "bugsage/dashboard"
require_relative "bugsage/middleware"
require_relative "bugsage/auto_configurator"
require_relative "bugsage/installation"
require_relative "bugsage/installer"
require_relative "bugsage/cli"
require_relative "bugsage/exceptions_app"

require_relative "bugsage/railtie" if defined?(Rails::Railtie)

Bugsage::Translations.load!

module Bugsage
  class Error < StandardError; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def t(key, **)
      Translations.t(key, **)
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
