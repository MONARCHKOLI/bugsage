# frozen_string_literal: true

module ExceptionScenarios
  SCENARIOS = [
    {
      name: "routing error",
      exception: -> { ActionController::RoutingError.new('No route matches [GET] "/us"') },
      issue: "ActionController::RoutingError",
      status: 404
    },
    {
      name: "no method error",
      exception: -> { NoMethodError.new("undefined method `foo' for nil:NilClass") },
      issue: "NoMethodError",
      status: 500
    },
    {
      name: "record not found",
      exception: -> { ActiveRecord::RecordNotFound.new("Couldn't find Post with id=99") },
      issue: "ActiveRecord::RecordNotFound",
      status: 404
    },
    {
      name: "parameter missing",
      exception: -> { ActionController::ParameterMissing.new("param is missing or the value is empty: title") },
      issue: "ActionController::ParameterMissing",
      status: 500
    },
    {
      name: "unpermitted parameters",
      exception: -> { ActionController::UnpermittedParameters.new("found unpermitted parameter: :admin") },
      issue: "ActionController::UnpermittedParameters",
      status: 500
    },
    {
      name: "record invalid",
      exception: -> { ActiveRecord::RecordInvalid.new("Validation failed: Name can't be blank") },
      issue: "ActiveRecord::RecordInvalid",
      status: 500
    },
    {
      name: "bad request",
      exception: -> { ActionController::BadRequest.new("Invalid request parameters") },
      issue: "ActionController::BadRequest",
      status: 500
    },
    {
      name: "invalid authenticity token",
      exception: -> { ActionController::InvalidAuthenticityToken.new("Can't verify CSRF token authenticity") },
      issue: "ActionController::InvalidAuthenticityToken",
      status: 500
    },
    {
      name: "parse error",
      exception: -> { ActionDispatch::Http::Parameters::ParseError.new("Unexpected character") },
      issue: "ActionDispatch::Http::Parameters::ParseError",
      status: 500
    },
    {
      name: "deserialization error",
      exception: -> { ActiveJob::DeserializationError.new("Failed to deserialize job") },
      issue: "ActiveJob::DeserializationError",
      status: 500
    },
    {
      name: "template error",
      exception: -> { ActionView::Template::Error.new("Missing template") },
      issue: "ActionView::Template::Error",
      status: 500
    },
    {
      name: "missing exact template",
      exception: -> { ActionController::MissingExactTemplate.new("Missing template for this request") },
      issue: "ActionController::MissingExactTemplate",
      status: 500
    },
    {
      name: "active storage file not found",
      exception: -> { ActiveStorage::FileNotFoundError.new("File not found") },
      issue: "ActiveStorage::FileNotFoundError",
      status: 500
    },
    {
      name: "redis error",
      exception: -> { Redis::BaseError.new("Connection refused") },
      issue: "Redis::BaseError",
      status: 500
    },
    {
      name: "faraday error",
      exception: -> { Faraday::Error.new("Connection failed") },
      issue: "Faraday::Error",
      status: 500
    },
    {
      name: "unknown format",
      exception: -> { ActionController::UnknownFormat.new("HTML format is not supported") },
      issue: "ActionController::UnknownFormat",
      status: 500
    },
    {
      name: "invalid cross origin request",
      exception: -> { ActionController::InvalidCrossOriginRequest.new("Security warning") },
      issue: "ActionController::InvalidCrossOriginRequest",
      status: 500
    },
    {
      name: "flash error",
      exception: -> { ActionDispatch::Flash::FlashError.new("Flash not available") },
      issue: "ActionDispatch::Flash::FlashError",
      status: 500
    },
    {
      name: "invalid signature",
      exception: -> { ActiveSupport::MessageVerifier::InvalidSignature.new("Signature verification failed") },
      issue: "ActiveSupport::MessageVerifier::InvalidSignature",
      status: 500
    },
    {
      name: "active storage integrity error",
      exception: -> { ActiveStorage::IntegrityError.new("Checksum mismatch") },
      issue: "ActiveStorage::IntegrityError",
      status: 500
    },
    {
      name: "record not unique",
      exception: -> { ActiveRecord::RecordNotUnique.new("duplicate key value violates unique constraint") },
      issue: "ActiveRecord::RecordNotUnique",
      status: 500
    },
    {
      name: "not null violation",
      exception: -> { ActiveRecord::NotNullViolation.new("null value in column violates not-null constraint") },
      issue: "ActiveRecord::NotNullViolation",
      status: 500
    },
    {
      name: "statement invalid",
      exception: -> { ActiveRecord::StatementInvalid.new("relation does not exist") },
      issue: "ActiveRecord::StatementInvalid",
      status: 500
    },
    {
      name: "connection not established",
      exception: -> { ActiveRecord::ConnectionNotEstablished.new("could not connect to server") },
      issue: "ActiveRecord::ConnectionNotEstablished",
      status: 500
    },
    {
      name: "stale object error",
      exception: -> { ActiveRecord::StaleObjectError.new("Attempted to update a stale object") },
      issue: "ActiveRecord::StaleObjectError",
      status: 500
    },
    {
      name: "pg error",
      exception: -> { PG::Error.new("server closed the connection unexpectedly") },
      issue: "PG::Error",
      status: 500
    },
    {
      name: "pg subclass error",
      exception: -> { PG::UniqueViolation.new("duplicate key value") },
      issue: "PG::UniqueViolation",
      status: 500
    },
    {
      name: "name error",
      exception: -> { NameError.new("uninitialized constant Foo") },
      issue: "NameError",
      status: 500
    },
    {
      name: "key error",
      exception: -> { KeyError.new("key not found: :missing") },
      issue: "KeyError",
      status: 500
    },
    {
      name: "argument error",
      exception: -> { ArgumentError.new("wrong number of arguments (given 0, expected 2)") },
      issue: "ArgumentError",
      status: 500
    },
    {
      name: "type error",
      exception: -> { TypeError.new("no implicit conversion of nil into String") },
      issue: "TypeError",
      status: 500
    },
    {
      name: "zero division error",
      exception: -> { ZeroDivisionError.new("divided by 0") },
      issue: "ZeroDivisionError",
      status: 500
    },
    {
      name: "json parser error",
      exception: -> { JSON::ParserError.new("unexpected token at 'x'") },
      issue: "JSON::ParserError",
      status: 500
    },
    {
      name: "frozen error",
      exception: -> { FrozenError.new("can't modify frozen String") },
      issue: "FrozenError",
      status: 500
    },
    {
      name: "runtime error",
      exception: -> { RuntimeError.new("This is a deliberate runtime error.") },
      issue: "RuntimeError",
      status: 500
    }
  ].freeze
end
