module Bugsage
  class Rule
    def self.match(exception)
      return nil unless exception.is_a?(Exception)

      case exception
      when NoMethodError
        match_no_method_error(exception)
      when defined?(ActiveRecord::RecordNotFound) ? ActiveRecord::RecordNotFound : nil
        match_record_not_found(exception)
      when defined?(ActionController::RoutingError) ? ActionController::RoutingError : nil
        match_routing_error(exception)
      when defined?(ActionController::ParameterMissing) ? ActionController::ParameterMissing : nil
        match_parameter_missing(exception)
      when defined?(ActionController::UnpermittedParameters) ? ActionController::UnpermittedParameters : nil
        match_unpermitted_parameters(exception)
      when defined?(ActiveRecord::RecordInvalid) ? ActiveRecord::RecordInvalid : nil
        match_record_invalid(exception)
      else
        match_generic_exception(exception)
      end
    end

    def self.match_no_method_error(exception)
      return nil unless exception.is_a?(NoMethodError)

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

    def self.match_routing_error(exception)
      Suggestion.new(
        issue: "ActionController::RoutingError",
        location: location_for(exception),
        root_cause: exception.message,
        fixes: [
          "Verify the requested route and path",
          "Check the controller and action names",
          "Confirm the route is defined in config/routes.rb"
        ],
        confidence: 92
      )
    end

    def self.match_parameter_missing(exception)
      Suggestion.new(
        issue: "ActionController::ParameterMissing",
        location: location_for(exception),
        root_cause: exception.message,
        fixes: [
          "Check the incoming parameters and required fields",
          "Ensure the expected form or query parameter is present",
          "Add a fallback or validation before accessing the parameter"
        ],
        confidence: 91
      )
    end

    def self.match_unpermitted_parameters(exception)
      Suggestion.new(
        issue: "ActionController::UnpermittedParameters",
        location: location_for(exception),
        root_cause: exception.message,
        fixes: [
          "Whitelist allowed parameters in your strong params",
          "Review the incoming payload shape",
          "Match the parameter names expected by your controller"
        ],
        confidence: 90
      )
    end

    def self.match_record_invalid(exception)
      Suggestion.new(
        issue: "ActiveRecord::RecordInvalid",
        location: location_for(exception),
        root_cause: exception.message,
        fixes: [
          "Check model validations and required attributes",
          "Inspect the form or payload being saved",
          "Add explicit validation messages for the user"
        ],
        confidence: 89
      )
    end

    def self.match_generic_exception(exception)
      Suggestion.new(
        issue: exception.class.name || "Exception",
        location: location_for(exception),
        root_cause: exception.message,
        fixes: [
          "Inspect the failing code path and surrounding stack trace",
          "Verify the expected input, state, or configuration",
          "Add a targeted rescue or validation around the failing operation"
        ],
        confidence: 75
      )
    end

    def self.location_for(exception)
      TraceCleaner.first_application_frame(exception.backtrace) || exception.backtrace&.first || "unknown"
    end
  end
end