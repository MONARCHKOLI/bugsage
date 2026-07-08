module Bugsage
  class Suggestion
    attr_reader :issue, :location, :root_cause, :fixes, :confidence

    def initialize(issue:, location:, root_cause:, fixes:, confidence:)
      @issue = issue
      @location = location
      @root_cause = root_cause
      @fixes = fixes
      @confidence = confidence
    end
  end
end