# frozen_string_literal: true

module Bugsage
  class Suggestion
    SOURCES = %i[rules ai hybrid].freeze

    attr_reader :issue, :location, :root_cause, :fixes, :confidence, :source, :ai_notes

    def initialize(issue:, location:, root_cause:, fixes:, confidence:, source: :rules, ai_notes: nil)
      @issue = issue
      @location = location
      @root_cause = root_cause
      @fixes = fixes
      @confidence = confidence
      @source = normalize_source(source)
      @ai_notes = ai_notes
    end

    def ai_enhanced?
      source == :hybrid || source == :ai
    end

    def with_ai_enhancement(root_cause:, fixes:, confidence:, ai_notes: nil)
      self.class.new(
        issue: issue,
        location: location,
        root_cause: root_cause,
        fixes: fixes,
        confidence: confidence,
        source: :hybrid,
        ai_notes: ai_notes
      )
    end

    private

    def normalize_source(source)
      symbol = source.to_sym
      SOURCES.include?(symbol) ? symbol : :rules
    end
  end
end
