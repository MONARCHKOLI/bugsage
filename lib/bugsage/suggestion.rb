# frozen_string_literal: true

module Bugsage
  class Suggestion
    SOURCES = %i[rules ai hybrid].freeze

    attr_reader :issue, :location, :root_cause, :fixes, :confidence, :source, :ai_notes, :code_patch

    def initialize(issue:, location:, root_cause:, fixes:, confidence:, source: :rules, ai_notes: nil, code_patch: nil,
                   code_fix: nil)
      @issue = issue
      @location = location
      @root_cause = root_cause
      @fixes = fixes
      @confidence = confidence
      @source = normalize_source(source)
      @ai_notes = ai_notes
      @code_patch = normalize_code_patch(code_patch, code_fix)
    end

    def code_fix
      CodePatch.preview_for(@code_patch)
    end

    def ai_enhanced?
      %i[hybrid ai].include?(source)
    end

    def with_ai_enhancement(root_cause:, fixes:, confidence:, ai_notes: nil, code_patch: nil)
      self.class.new(
        issue: issue,
        location: location,
        root_cause: root_cause,
        fixes: fixes,
        confidence: confidence,
        source: :hybrid,
        ai_notes: ai_notes,
        code_patch: code_patch || @code_patch
      )
    end

    private

    def normalize_source(source)
      symbol = source.to_sym
      SOURCES.include?(symbol) ? symbol : :rules
    end

    def normalize_code_patch(code_patch, legacy_code_fix)
      return code_patch if code_patch.is_a?(Hash) && !code_patch.empty?
      return nil if legacy_code_fix.to_s.strip.empty?

      _, line_number = CodeContext.extract_location(location)
      legacy = CodePatch.from_legacy(legacy_code_fix, line_number || 1)
      legacy&.to_h
    end
  end
end
