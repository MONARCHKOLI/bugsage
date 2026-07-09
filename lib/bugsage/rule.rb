# frozen_string_literal: true

module Bugsage
  class Rule
    # Ordering matters: more specific classes must be listed before their
    # parents because matching walks the exception's ancestor chain.
    MATCHERS = [
      { classes: ["ActionController::RoutingError"], message: /No route matches/i, handler: :match_routing_error },
      { classes: ["NoMethodError"], handler: :match_no_method_error },
      { classes: ["ActiveRecord::RecordNotFound"], handler: :match_record_not_found },
      { classes: ["ActionController::ParameterMissing"], handler: :match_parameter_missing },
      { classes: ["ActionController::UnpermittedParameters"], handler: :match_unpermitted_parameters },
      { classes: ["ActionController::BadRequest"], handler: :match_bad_request },
      { classes: ["ActionController::InvalidAuthenticityToken"], handler: :match_invalid_authenticity_token },
      { classes: ["ActionDispatch::Http::Parameters::ParseError"], handler: :match_parse_error },
      { classes: ["ActiveJob::DeserializationError"], handler: :match_deserialization_error },
      { classes: ["ActionView::Template::Error"], handler: :match_template_error },
      { classes: ["ActionController::MissingExactTemplate"], handler: :match_missing_exact_template },
      { classes: ["ActionController::UnknownFormat"], handler: :match_unknown_format },
      { classes: ["ActionController::InvalidCrossOriginRequest"], handler: :match_invalid_cross_origin_request },
      { classes: ["ActionDispatch::Flash::FlashError"], handler: :match_flash_error },
      { classes: ["ActiveStorage::FileNotFoundError"], handler: :match_active_storage_error },
      { classes: ["ActiveStorage::IntegrityError"], handler: :match_active_storage_integrity_error },
      { classes: ["ActiveSupport::MessageVerifier::InvalidSignature"], handler: :match_invalid_signature },
      # Database — specific violations before the generic StatementInvalid.
      { classes: ["ActiveRecord::RecordNotUnique"], handler: :match_record_not_unique },
      { classes: ["ActiveRecord::NotNullViolation"], handler: :match_not_null_violation },
      { classes: ["ActiveRecord::StatementInvalid"], handler: :match_statement_invalid },
      { classes: ["ActiveRecord::ConnectionNotEstablished"], handler: :match_connection_not_established },
      { classes: ["ActiveRecord::StaleObjectError"], handler: :match_stale_object },
      { classes: ["ActiveRecord::RecordInvalid"], handler: :match_record_invalid },
      { classes: ["PG::Error"], handler: :match_pg_error },
      { classes: ["Redis::BaseError"], handler: :match_redis_error },
      { classes: ["Faraday::Error"], handler: :match_faraday_error },
      # Ruby core — NoMethodError (above) is a subclass of NameError, so it wins first.
      { classes: ["NameError"], handler: :match_name_error },
      { classes: ["KeyError"], handler: :match_key_error },
      { classes: ["ArgumentError"], handler: :match_argument_error },
      { classes: ["TypeError"], handler: :match_type_error },
      { classes: ["ZeroDivisionError"], handler: :match_zero_division_error },
      { classes: ["JSON::ParserError"], handler: :match_json_parse_error },
      { classes: ["Net::OpenTimeout", "Net::ReadTimeout", "Timeout::Error"], message: /timed out|timeout|execution expired/i, handler: :match_timeout_error },
      { classes: ["FrozenError"], handler: :match_frozen_error },
      { classes: ["RuntimeError"], handler: :match_runtime_error }
    ].freeze

    def self.match(exception)
      exception = ExceptionSupport.unwrap(exception)
      return nil unless exception.is_a?(Exception)

      handler = matcher_for(exception)
      send(handler, exception)
    end

    def self.matcher_for(exception)
      definition = MATCHERS.find { |matcher| matches_definition?(exception, matcher) }
      definition&.fetch(:handler) || :match_generic_exception
    end

    def self.matches_definition?(exception, definition)
      if definition[:classes]&.any? { |class_name| ExceptionSupport.matches_class?(exception, class_name) }
        return true
      end

      if definition[:message] && ExceptionSupport.message_matches?(exception, definition[:message])
        return true
      end

      false
    end

    def self.match_no_method_error(exception)
      build_suggestion(
        exception: exception,
        issue: "NoMethodError",
        root_cause: exception.message.to_s.empty? ? "Called a method on an unexpected object" : exception.message,
        fixes: ["Check object initialization", "Add nil guard", "Verify the method exists on the receiver"],
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

    def self.match_record_not_unique(exception)
      build_suggestion(
        exception: exception,
        issue: "ActiveRecord::RecordNotUnique",
        root_cause: exception.message,
        fixes: [
          "Check for a unique index or constraint being violated",
          "Look up the existing record before inserting a duplicate",
          "Use find_or_create_by or upsert to avoid duplicate inserts"
        ],
        confidence: 90
      )
    end

    def self.match_not_null_violation(exception)
      build_suggestion(
        exception: exception,
        issue: "ActiveRecord::NotNullViolation",
        root_cause: exception.message,
        fixes: [
          "Provide a value for the NOT NULL column being inserted",
          "Add a default value or make the column nullable in a migration",
          "Validate presence of the attribute before saving"
        ],
        confidence: 89
      )
    end

    def self.match_statement_invalid(exception)
      build_suggestion(
        exception: exception,
        issue: "ActiveRecord::StatementInvalid",
        root_cause: exception.message,
        fixes: [
          "Inspect the generated SQL and the underlying database error",
          "Check for missing columns, tables, or pending migrations",
          "Verify data types and query arguments match the schema"
        ],
        confidence: 86
      )
    end

    def self.match_connection_not_established(exception)
      build_suggestion(
        exception: exception,
        issue: "ActiveRecord::ConnectionNotEstablished",
        root_cause: exception.message,
        fixes: [
          "Verify the database is running and reachable",
          "Check database.yml credentials, host, and pool settings",
          "Ensure the connection pool is not exhausted under load"
        ],
        confidence: 88
      )
    end

    def self.match_stale_object(exception)
      build_suggestion(
        exception: exception,
        issue: "ActiveRecord::StaleObjectError",
        root_cause: exception.message,
        fixes: [
          "Reload the record before retrying the update",
          "Handle optimistic locking conflicts with a rescue and retry",
          "Confirm the lock_version column is being tracked correctly"
        ],
        confidence: 87
      )
    end

    def self.match_pg_error(exception)
      build_suggestion(
        exception: exception,
        issue: exception.class.name || "PG::Error",
        root_cause: exception.message,
        fixes: [
          "Inspect the PostgreSQL error detail in the message",
          "Verify the connection, credentials, and database availability",
          "Check the query, constraints, and column definitions"
        ],
        confidence: 85
      )
    end

    def self.match_name_error(exception)
      build_suggestion(
        exception: exception,
        issue: "NameError",
        root_cause: exception.message,
        fixes: [
          "Check for a typo in the constant, class, or variable name",
          "Ensure the referenced class or module is required and loaded",
          "Verify the name is defined in the current scope"
        ],
        confidence: 88
      )
    end

    def self.match_key_error(exception)
      build_suggestion(
        exception: exception,
        issue: "KeyError",
        root_cause: exception.message,
        fixes: [
          "Verify the key exists before accessing it with fetch",
          "Provide a default value to Hash#fetch",
          "Check the source data for the expected keys"
        ],
        confidence: 86
      )
    end

    def self.match_argument_error(exception)
      build_suggestion(
        exception: exception,
        issue: "ArgumentError",
        root_cause: exception.message,
        fixes: [
          "Check the number and order of arguments passed",
          "Verify keyword arguments match the method signature",
          "Inspect the value being passed for the expected type or range"
        ],
        confidence: 85
      )
    end

    def self.match_type_error(exception)
      build_suggestion(
        exception: exception,
        issue: "TypeError",
        root_cause: exception.message,
        fixes: [
          "Ensure the value is the expected type before using it",
          "Add an explicit conversion (to_s, to_i, to_a) where needed",
          "Guard against nil or unexpected objects in the operation"
        ],
        confidence: 85
      )
    end

    def self.match_zero_division_error(exception)
      build_suggestion(
        exception: exception,
        issue: "ZeroDivisionError",
        root_cause: exception.message,
        fixes: [
          "Guard against a zero divisor before dividing",
          "Return a default or nil when the denominator is zero",
          "Validate the input values feeding the calculation"
        ],
        confidence: 90
      )
    end

    def self.match_json_parse_error(exception)
      build_suggestion(
        exception: exception,
        issue: exception.class.name || "JSON::ParserError",
        root_cause: exception.message,
        fixes: [
          "Verify the payload is valid JSON before parsing",
          "Rescue JSON::ParserError and handle malformed input",
          "Check the content type and encoding of the source data"
        ],
        confidence: 88
      )
    end

    def self.match_timeout_error(exception)
      build_suggestion(
        exception: exception,
        issue: exception.class.name || "Timeout::Error",
        root_cause: exception.message,
        fixes: [
          "Increase the timeout for the slow operation if appropriate",
          "Inspect the upstream service or query that is running long",
          "Add retries with backoff for transient timeouts"
        ],
        confidence: 84
      )
    end

    def self.match_frozen_error(exception)
      build_suggestion(
        exception: exception,
        issue: "FrozenError",
        root_cause: exception.message,
        fixes: [
          "Avoid mutating a frozen object; work on a duplicate with dup",
          "Check for frozen string literals when modifying strings",
          "Build a new object instead of mutating the frozen one"
        ],
        confidence: 87
      )
    end

    def self.match_runtime_error(exception)
      build_suggestion(
        exception: exception,
        issue: exception.class.name || "RuntimeError",
        root_cause: exception.message,
        fixes: [
          "Read the error message for the specific failure",
          "Inspect the code path that raised the error",
          "Add handling or validation around the failing operation"
        ],
        confidence: 80
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
