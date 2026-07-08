module Bugsage
  class Rule
    def self.match(exception)
      return nil unless exception.is_a?(NoMethodError)
      return nil unless exception.message.include?("nil")

      Suggestion.new(
        issue: "NoMethodError",
        location: TraceCleaner.first_application_frame(exception.backtrace) || exception.backtrace&.first || "unknown",
        root_cause: "Called a method on a nil object",
        fixes: ["Check object initialization", "Add nil guard", "Verify authentication"],
        confidence: 95
      )
    end
  end
end