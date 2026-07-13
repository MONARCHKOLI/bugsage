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
      { classes: ["Bugsage::HttpResponseError"], handler: :match_http_response_error },
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
      { classes: ["Net::OpenTimeout", "Net::ReadTimeout", "Timeout::Error"],
        message: /timed out|timeout|execution expired/i, handler: :match_timeout_error },
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
      return true if definition[:classes]&.any? { |class_name| ExceptionSupport.matches_class?(exception, class_name) }

      return true if definition[:message] && ExceptionSupport.message_matches?(exception, definition[:message])

      false
    end

    def self.rule_fixes(key)
      Array(Bugsage.t("rules.#{key}.fixes"))
    end

    def self.rule_issue(key, exception)
      issue = Bugsage.t("rules.#{key}.issue", default: nil)
      return issue if issue

      class_name = exception.class.name.to_s
      return class_name unless class_name.empty?

      Bugsage.t("rules.#{key}.issue_fallback", default: class_name)
    end

    def self.from_rule(key, exception, confidence:, root_cause: nil)
      build_suggestion(
        exception: exception,
        issue: rule_issue(key, exception),
        root_cause: root_cause.nil? ? exception.message : root_cause,
        fixes: rule_fixes(key),
        confidence: confidence
      )
    end

    def self.match_no_method_error(exception)
      root_cause = if exception.message.to_s.empty?
                     Bugsage.t("rules.no_method_error.root_cause_default")
                   else
                     exception.message
                   end
      from_rule(:no_method_error, exception, confidence: 95, root_cause: root_cause)
    end

    def self.match_record_not_found(exception)
      from_rule(:record_not_found, exception, confidence: 90)
    end

    def self.match_routing_error(exception)
      from_rule(:routing_error, exception, confidence: 92)
    end

    def self.match_parameter_missing(exception)
      from_rule(:parameter_missing, exception, confidence: 91)
    end

    def self.match_unpermitted_parameters(exception)
      from_rule(:unpermitted_parameters, exception, confidence: 90)
    end

    def self.match_bad_request(exception)
      from_rule(:bad_request, exception, confidence: 88)
    end

    def self.match_http_response_error(exception)
      status = exception.status
      build_suggestion(
        exception: exception,
        issue: Bugsage.t("http_errors.issue", status: status),
        root_cause: exception.message,
        fixes: HttpErrorCapture.fixes_for_status(status),
        confidence: HttpErrorCapture.confidence_for_status(status)
      )
    end

    def self.match_invalid_authenticity_token(exception)
      from_rule(:invalid_authenticity_token, exception, confidence: 91)
    end

    def self.match_parse_error(exception)
      from_rule(:parse_error, exception, confidence: 88)
    end

    def self.match_deserialization_error(exception)
      from_rule(:deserialization_error, exception, confidence: 87)
    end

    def self.match_template_error(exception)
      from_rule(:template_error, exception, confidence: 88)
    end

    def self.match_missing_exact_template(exception)
      from_rule(:missing_exact_template, exception, confidence: 88)
    end

    def self.match_active_storage_error(exception)
      from_rule(:active_storage_error, exception, confidence: 87)
    end

    def self.match_active_storage_integrity_error(exception)
      from_rule(:active_storage_integrity_error, exception, confidence: 88)
    end

    def self.match_redis_error(exception)
      from_rule(:redis_error, exception, confidence: 86)
    end

    def self.match_unknown_format(exception)
      from_rule(:unknown_format, exception, confidence: 87)
    end

    def self.match_invalid_cross_origin_request(exception)
      from_rule(:invalid_cross_origin_request, exception, confidence: 88)
    end

    def self.match_flash_error(exception)
      from_rule(:flash_error, exception, confidence: 86)
    end

    def self.match_invalid_signature(exception)
      from_rule(:invalid_signature, exception, confidence: 88)
    end

    def self.match_faraday_error(exception)
      from_rule(:faraday_error, exception, confidence: 85)
    end

    def self.match_record_invalid(exception)
      from_rule(:record_invalid, exception, confidence: 89)
    end

    def self.match_record_not_unique(exception)
      from_rule(:record_not_unique, exception, confidence: 90)
    end

    def self.match_not_null_violation(exception)
      from_rule(:not_null_violation, exception, confidence: 89)
    end

    def self.match_statement_invalid(exception)
      from_rule(:statement_invalid, exception, confidence: 86)
    end

    def self.match_connection_not_established(exception)
      from_rule(:connection_not_established, exception, confidence: 88)
    end

    def self.match_stale_object(exception)
      from_rule(:stale_object, exception, confidence: 87)
    end

    def self.match_pg_error(exception)
      from_rule(:pg_error, exception, confidence: 85)
    end

    def self.match_name_error(exception)
      from_rule(:name_error, exception, confidence: 88)
    end

    def self.match_key_error(exception)
      from_rule(:key_error, exception, confidence: 86)
    end

    def self.match_argument_error(exception)
      from_rule(:argument_error, exception, confidence: 85)
    end

    def self.match_type_error(exception)
      from_rule(:type_error, exception, confidence: 85)
    end

    def self.match_zero_division_error(exception)
      from_rule(:zero_division_error, exception, confidence: 90)
    end

    def self.match_json_parse_error(exception)
      from_rule(:json_parse_error, exception, confidence: 88)
    end

    def self.match_timeout_error(exception)
      from_rule(:timeout_error, exception, confidence: 84)
    end

    def self.match_frozen_error(exception)
      from_rule(:frozen_error, exception, confidence: 87)
    end

    def self.match_runtime_error(exception)
      from_rule(:runtime_error, exception, confidence: 80)
    end

    def self.match_generic_exception(exception)
      from_rule(:generic_exception, exception, confidence: 75)
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
      return exception.location if exception.respond_to?(:location) && !exception.location.to_s.strip.empty?

      frame = TraceCleaner.first_application_frame(exception.backtrace) || exception.backtrace&.first
      frame || Bugsage.t("common.unknown")
    end
  end
end
