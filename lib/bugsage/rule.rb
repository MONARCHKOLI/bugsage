module Bugsage
  class Rule
    def self.match(exception)
      case exception
      when NoMethodError
        match_no_method_error(exception)
      when ActiveRecord::RecordNotFound
        match_record_not_found(exception)
      end
    end

    def self.match_no_method_error(exception)
      return nil unless exception.message.include?("nil")

      Suggestion.new(
        issue: "NoMethodError",
        location: location_for(exception),
        root_cause: "Called a method on a nil object",
        fixes: ["Check object initialization", "Add nil guard", "Verify authentication"],
        confidence: 95
      )
    end

    def self.match_record_not_found(exception)
      Suggestion.new(
        issue: "ActiveRecord::RecordNotFound",
        location: location_for(exception),
        root_cause: exception.message,
        fixes: [
          "Verify the record ID exists before querying",
          "Use find_by instead of find if a missing record is expected",
          "Add a rescue_from ActiveRecord::RecordNotFound handler for a friendly 404 page"
        ],
        confidence: 90
      )
    end

    def self.location_for(exception)
      TraceCleaner.first_application_frame(exception.backtrace) || exception.backtrace&.first || "unknown"
    end
  end
end