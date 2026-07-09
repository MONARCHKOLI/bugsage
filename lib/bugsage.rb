# frozen_string_literal: true

require_relative "bugsage/version"
require_relative "bugsage/suggestion"
require_relative "bugsage/trace_cleaner"
require_relative "bugsage/rule"
require_relative "bugsage/formatter"
require_relative "bugsage/store"
require_relative "bugsage/error_page"
require_relative "bugsage/dashboard"
require_relative "bugsage/middleware"
require_relative "bugsage/cli"
require_relative "bugsage/exceptions_app"

module Bugsage
  class Error < StandardError; end
end
