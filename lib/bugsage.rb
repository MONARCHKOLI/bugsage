require_relative "bugsage/version"
require_relative "bugsage/suggestion"
require_relative "bugsage/trace_cleaner"
require_relative "bugsage/rule"
require_relative "bugsage/formatter"
require_relative "bugsage/cli"

module Bugsage
  class Error < StandardError; end
end