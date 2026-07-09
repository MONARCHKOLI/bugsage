# frozen_string_literal: true

module Bugsage
  class Rule
    MATCHERS = [
      [->(exception) { exception.is_a?(NoMethodError) }, :match_no_method_error],
      [->(exception) { defined?(ActiveRecord::RecordNotFound) && exception.is_a?(ActiveRecord::RecordNotFound) },
       :match_record_not_found],
      [lambda do |exception|
         defined?(ActionController::RoutingError) && exception.is_a?(ActionController::RoutingError)
       end, :match_routing_error],
      [lambda do |exception|
         defined?(ActionController::ParameterMissing) && exception.is_a?(ActionController::ParameterMissing)
       end, :match_parameter_missing],
      [lambda do |exception|
         defined?(ActionController::UnpermittedParameters) && exception.is_a?(ActionController::UnpermittedParameters)
       end, :match_unpermitted_parameters],
      [lambda do |exception|
         defined?(ActionController::BadRequest) && exception.is_a?(ActionController::BadRequest)
       end, :match_bad_request],
      [lambda do |exception|
         defined?(ActionController::InvalidAuthenticityToken) && exception.is_a?(ActionController::InvalidAuthenticityToken)
       end, :match_invalid_authenticity_token],
      [lambda do |exception|
         defined?(ActionDispatch::Http::Parameters::ParseError) && exception.is_a?(ActionDispatch::Http::Parameters::ParseError)
       end, :match_parse_error],
      [lambda do |exception|
         defined?(ActiveJob::DeserializationError) && exception.is_a?(ActiveJob::DeserializationError)
       end, :match_deserialization_error],
      [lambda do |exception|
         defined?(ActionView::Template::Error) && exception.is_a?(ActionView::Template::Error)
       end, :match_template_error],
      [lambda do |exception|
         defined?(ActionController::MissingExactTemplate) && exception.is_a?(ActionController::MissingExactTemplate)
       end, :match_missing_exact_template],
      [lambda do |exception|
         defined?(ActionController::UnknownFormat) && exception.is_a?(ActionController::UnknownFormat)
       end, :match_unknown_format],
      [lambda do |exception|
         defined?(ActionController::InvalidCrossOriginRequest) && exception.is_a?(ActionController::InvalidCrossOriginRequest)
       end, :match_invalid_cross_origin_request],
      [lambda do |exception|
         defined?(ActionDispatch::Flash::FlashError) && exception.is_a?(ActionDispatch::Flash::FlashError)
       end, :match_flash_error],
      [lambda do |exception|
         defined?(ActiveStorage::FileNotFoundError) && exception.is_a?(ActiveStorage::FileNotFoundError)
       end, :match_active_storage_error],
      [lambda do |exception|
         defined?(ActiveStorage::IntegrityError) && exception.is_a?(ActiveStorage::IntegrityError)
       end, :match_active_storage_integrity_error],
      [lambda do |exception|
         defined?(Redis::BaseError) && exception.is_a?(Redis::BaseError)
       end, :match_redis_error],
      [lambda do |exception|
         defined?(ActiveSupport::MessageVerifier::InvalidSignature) && exception.is_a?(ActiveSupport::MessageVerifier::InvalidSignature)
       end, :match_invalid_signature],
      [lambda do |exception|
         defined?(Faraday::Error) && exception.is_a?(Faraday::Error)
       end, :match_faraday_error],
      [lambda do |exception|
         defined?(ActiveRecord::RecordNotFound) && exception.is_a?(ActiveRecord::RecordNotFound)
       end, :match_record_not_found],
      [lambda do |exception|
         defined?(ActiveRecord::RecordInvalid) && exception.is_a?(ActiveRecord::RecordInvalid)
       end, :match_record_invalid]
    ].freeze

    def self.match(exception)
      return nil unless exception.is_a?(Exception)

      matcher = matcher_for(exception)
      return nil unless matcher

      send(matcher, exception)
    end

    def self.matcher_for(exception)
      match = MATCHERS.find { |matcher, _method_name| matcher.call(exception) }
      match&.last || :match_generic_exception
    end

    def self.match_no_method_error(exception)
      return nil unless exception.is_a?(NoMethodError)

      build_suggestion(
        exception: exception,
        issue: "NoMethodError",
        root_cause: "Called a method on a nil object",
        fixes: ["Check object initialization", "Add nil guard", "Verify authentication"],
        confidence: 95
      )
    end

    def self.match_record_not_found(exception)
      build_suggestion(
        exception: exception,
        issue: "ActiveRecord::RecordNotFound",
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
      build_suggestion(
        exception: exception,
        issue: "ActionController::RoutingError",
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
      build_suggestion(
        exception: exception,
        issue: "ActionController::ParameterMissing",
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
      build_suggestion(
        exception: exception,
        issue: "ActionController::UnpermittedParameters",
        root_cause: exception.message,
        fixes: [
          "Whitelist allowed parameters in your strong params",
          "Review the incoming payload shape",
          "Match the parameter names expected by your controller"
        ],
        confidence: 90
      )
    end

    def self.match_bad_request(exception)
      build_suggestion(
        exception: exception,
        issue: "ActionController::BadRequest",
        root_cause: exception.message,
        fixes: [
          "Verify the request payload and expected format",
          "Check parameter names and content types",
          "Add a rescue handler for malformed requests"
        ],
        confidence: 88
      )
    end

    def self.match_invalid_authenticity_token(exception)
      build_suggestion(
        exception: exception,
        issue: "ActionController::InvalidAuthenticityToken",
        root_cause: exception.message,
        fixes: [
          "Ensure the form includes the CSRF token",
          "Review token generation and session persistence",
          "Verify that the request is coming from the expected origin"
        ],
        confidence: 91
      )
    end

    def self.match_parse_error(exception)
      build_suggestion(
        exception: exception,
        issue: "ActionDispatch::Http::Parameters::ParseError",
        root_cause: exception.message,
        fixes: [
          "Verify the request body format and encoding",
          "Inspect the client payload being sent",
          "Ensure the server accepts the expected content type"
        ],
        confidence: 88
      )
    end

    def self.match_deserialization_error(exception)
      build_suggestion(
        exception: exception,
        issue: "ActiveJob::DeserializationError",
        root_cause: exception.message,
        fixes: [
          "Check job payload compatibility and serializer setup",
          "Ensure referenced classes are still present",
          "Review recent model or job changes that could break deserialization"
        ],
        confidence: 89
      )
    end

    def self.match_template_error(exception)
      build_suggestion(
        exception: exception,
        issue: "ActionView::Template::Error",
        root_cause: exception.message,
        fixes: [
          "Verify the template name and format",
          "Check the view file exists and uses the expected layout",
          "Review partials or helpers referenced by the view"
        ],
        confidence: 88
      )
    end

    def self.match_missing_exact_template(exception)
      build_suggestion(
        exception: exception,
        issue: "ActionController::MissingExactTemplate",
        root_cause: exception.message,
        fixes: [
          "Add the expected template for the requested format",
          "Check the request format and route constraints",
          "Ensure the appropriate template exists for the action"
        ],
        confidence: 89
      )
    end

    def self.match_active_storage_error(exception)
      build_suggestion(
        exception: exception,
        issue: "ActiveStorage::FileNotFoundError",
        root_cause: exception.message,
        fixes: [
          "Verify the storage object exists and the key is correct",
          "Check the file upload or attachment lifecycle",
          "Ensure the backing storage service is reachable"
        ],
        confidence: 87
      )
    end

    def self.match_active_storage_integrity_error(exception)
      build_suggestion(
        exception: exception,
        issue: "ActiveStorage::IntegrityError",
        root_cause: exception.message,
        fixes: [
          "Validate uploaded content and storage integrity",
          "Check for partial uploads or corrupted blobs",
          "Review the storage backend and file transfer path"
        ],
        confidence: 88
      )
    end

    def self.match_redis_error(exception)
      build_suggestion(
        exception: exception,
        issue: "Redis::BaseError",
        root_cause: exception.message,
        fixes: [
          "Verify the Redis connection settings and service availability",
          "Check authentication credentials and network access",
          "Inspect the Redis client configuration and timeouts"
        ],
        confidence: 86
      )
    end

    def self.match_unknown_format(exception)
      build_suggestion(
        exception: exception,
        issue: "ActionController::UnknownFormat",
        root_cause: exception.message,
        fixes: [
          "Check the requested format and respond with a supported one",
          "Verify the request format or content negotiation logic",
          "Add a fallback response for unsupported formats"
        ],
        confidence: 87
      )
    end

    def self.match_invalid_cross_origin_request(exception)
      build_suggestion(
        exception: exception,
        issue: "ActionController::InvalidCrossOriginRequest",
        root_cause: exception.message,
        fixes: [
          "Verify the CORS configuration and request origin",
          "Check the allowed methods, headers, and credentials settings",
          "Review browser preflight requests against your policy"
        ],
        confidence: 88
      )
    end

    def self.match_flash_error(exception)
      build_suggestion(
        exception: exception,
        issue: "ActionDispatch::Flash::FlashError",
        root_cause: exception.message,
        fixes: [
          "Check flash usage and session persistence",
          "Ensure the session store is available",
          "Review code that writes or reads flash state"
        ],
        confidence: 86
      )
    end

    def self.match_invalid_signature(exception)
      build_suggestion(
        exception: exception,
        issue: "ActiveSupport::MessageVerifier::InvalidSignature",
        root_cause: exception.message,
        fixes: [
          "Verify the signed payload and secret rotation",
          "Check for tampered or expired tokens",
          "Review message generation and verification paths"
        ],
        confidence: 88
      )
    end

    def self.match_faraday_error(exception)
      build_suggestion(
        exception: exception,
        issue: "Faraday::Error",
        root_cause: exception.message,
        fixes: [
          "Inspect the upstream service and network connectivity",
          "Verify request headers, auth, and timeout settings",
          "Review recent API contract or endpoint changes"
        ],
        confidence: 85
      )
    end

    def self.match_record_invalid(exception)
      build_suggestion(
        exception: exception,
        issue: "ActiveRecord::RecordInvalid",
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
      build_suggestion(
        exception: exception,
        issue: exception.class.name || "Exception",
        root_cause: exception.message,
        fixes: [
          "Inspect the failing code path and surrounding stack trace",
          "Verify the expected input, state, or configuration",
          "Add a targeted rescue or validation around the failing operation"
        ],
        confidence: 75
      )
    end

    def self.build_suggestion(exception:, issue:, root_cause:, fixes:, confidence:)
      Suggestion.new(
        issue: issue,
        location: location_for(exception),
        root_cause: root_cause,
        fixes: fixes,
        confidence: confidence
      )
    end

    def self.location_for(exception)
      TraceCleaner.first_application_frame(exception.backtrace) || exception.backtrace&.first || "unknown"
    end
  end
end
