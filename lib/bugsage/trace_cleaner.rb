# frozen_string_literal: true

module Bugsage
  class TraceCleaner
    FRAMEWORK_PATTERNS = [
      %r{/gems/},
      %r{/ruby/\d}
    ].freeze

    def self.clean(backtrace)
      return [] unless backtrace

      backtrace.reject { |line| framework_line?(line) }
    end

    def self.first_application_frame(backtrace)
      clean(backtrace).first
    end

    def self.framework_line?(line)
      FRAMEWORK_PATTERNS.any? { |pattern| line.match?(pattern) }
    end
  end
end
