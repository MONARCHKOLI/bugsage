# frozen_string_literal: true

require "pastel"

module Bugsage
  class Formatter
    def self.print(suggestion)
      pastel = Pastel.new
      print_header(pastel, "BugSage Analysis")
      print_section(pastel, "Issue", suggestion.issue)
      print_section(pastel, "Location", suggestion.location)
      print_section(pastel, "Root Cause", suggestion.root_cause)
      print_fixes(pastel, suggestion.fixes)
      print_section(pastel, "Confidence", "#{suggestion.confidence}%")
    end

    def self.print_header(pastel, title)
      puts pastel.bold(title)
      puts
    end

    def self.print_section(pastel, label, value)
      puts pastel.bold(label)
      puts value
      puts
    end

    def self.print_fixes(pastel, fixes)
      puts pastel.bold("Suggested Fixes")
      fixes.each { |fix| puts pastel.green("✓ ") + fix }
      puts
    end
  end
end
