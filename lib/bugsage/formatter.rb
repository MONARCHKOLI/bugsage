# frozen_string_literal: true

require "pastel"

module Bugsage
  class Formatter
    def self.print(suggestion)
      pastel = Pastel.new
      print_header(pastel, Bugsage.t("ui.formatter.analysis"))
      print_section(pastel, Bugsage.t("ui.formatter.issue"), suggestion.issue)
      print_section(pastel, Bugsage.t("ui.formatter.location"), suggestion.location)
      print_section(pastel, Bugsage.t("ui.formatter.root_cause"), suggestion.root_cause)
      print_fixes(pastel, suggestion.fixes)
      print_section(pastel, Bugsage.t("ui.formatter.confidence"),
                    Bugsage.t("ui.formatter.confidence_value", confidence: suggestion.confidence))
      print_section(pastel, Bugsage.t("ui.formatter.source"), suggestion.source.to_s) if suggestion.ai_enhanced?
      print_section(pastel, Bugsage.t("ui.formatter.ai_notes"), suggestion.ai_notes) if suggestion.ai_notes
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
      puts pastel.bold(Bugsage.t("ui.formatter.suggested_fixes"))
      fixes.each { |fix| puts pastel.green("✓ ") + fix }
      puts
    end
  end
end
