# frozen_string_literal: true

require_relative "bugsage/version"
require_relative "bugsage/configuration"
require_relative "bugsage/suggestion"
require_relative "bugsage/trace_cleaner"
require_relative "bugsage/exception_support"
require_relative "bugsage/code_context"
require_relative "bugsage/rule"
require_relative "bugsage/openai_client"
require_relative "bugsage/cursor_client"
require_relative "bugsage/ai_analyzer"
require_relative "bugsage/formatter"
require_relative "bugsage/store"
require_relative "bugsage/console_context"
require_relative "bugsage/inline_console"
require_relative "bugsage/exception_handler"
require_relative "bugsage/error_page"
require_relative "bugsage/dashboard"
require_relative "bugsage/middleware"
require_relative "bugsage/cli"
require_relative "bugsage/exceptions_app"

require_relative "bugsage/railtie" if defined?(Rails::Railtie)

module Bugsage
  class Error < StandardError; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
