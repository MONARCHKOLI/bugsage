require "pastel"

module Bugsage
  class Formatter
    def self.print(suggestion)
      pastel = Pastel.new
      puts pastel.bold("BugSage Analysis")
      puts
      puts pastel.bold("Issue")
      puts suggestion.issue
      puts
      puts pastel.bold("Location")
      puts suggestion.location
      puts
      puts pastel.bold("Root Cause")
      puts suggestion.root_cause
      puts
      puts pastel.bold("Suggested Fixes")
      suggestion.fixes.each { |f| puts pastel.green("✓ ") + f }
      puts
      puts pastel.bold("Confidence")
      puts "#{suggestion.confidence}%"
    end
  end
end