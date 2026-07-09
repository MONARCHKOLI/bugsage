# frozen_string_literal: true

unless defined?(ActionController::RoutingError)
  module ActionController
    class RoutingError < StandardError; end
    class ParameterMissing < StandardError; end
    class UnpermittedParameters < StandardError; end
    class BadRequest < StandardError; end
    class InvalidAuthenticityToken < StandardError; end
    class MissingExactTemplate < StandardError; end
    class UnknownFormat < StandardError; end
    class InvalidCrossOriginRequest < StandardError; end
  end
end

unless defined?(ActionDispatch::Http::Parameters::ParseError)
  module ActionDispatch
    module Http
      module Parameters
        class ParseError < StandardError; end
      end
    end
  end
end

unless defined?(ActionView::Template::Error)
  module ActionView
    module Template
      class Error < StandardError; end
    end
  end
end

unless defined?(ActionDispatch::Flash::FlashError)
  module ActionDispatch
    module Flash
      class FlashError < StandardError; end
    end
  end
end

unless defined?(ActiveJob::DeserializationError)
  module ActiveJob
    class DeserializationError < StandardError; end
  end
end

unless defined?(ActiveRecord::RecordInvalid)
  module ActiveRecord
    class RecordInvalid < StandardError; end
    class RecordNotFound < StandardError; end
  end
end

unless defined?(ActiveStorage::FileNotFoundError)
  module ActiveStorage
    class FileNotFoundError < StandardError; end
    class IntegrityError < StandardError; end
  end
end

unless defined?(Redis::BaseError)
  module Redis
    class BaseError < StandardError; end
  end
end

unless defined?(ActiveSupport::MessageVerifier::InvalidSignature)
  module ActiveSupport
    module MessageVerifier
      class InvalidSignature < StandardError; end
    end
  end
end

unless defined?(Faraday::Error)
  module Faraday
    class Error < StandardError; end
  end
end

RSpec.describe Bugsage do
  it "has a version number" do
    expect(Bugsage::VERSION).not_to be nil
  end

  describe Bugsage::Rule do
    it "matches generic NoMethodError exceptions" do
      exception = NoMethodError.new("undefined method `foo' for an instance of String")

      suggestion = described_class.match(exception)

      expect(suggestion).not_to be_nil
      expect(suggestion.issue).to eq("NoMethodError")
      expect(suggestion.fixes).to include("Check object initialization")
    end

    it "matches routing errors with a helpful suggestion" do
      exception = ActionController::RoutingError.new("No route matches [GET] /missing")

      suggestion = described_class.match(exception)

      expect(suggestion.issue).to eq("ActionController::RoutingError")
      expect(suggestion.root_cause).to include("No route matches")
      expect(suggestion.fixes).to include("Verify the requested route and path")
    end

    it "matches parameter missing errors" do
      exception = ActionController::ParameterMissing.new("param is missing or the value is empty: title")

      suggestion = described_class.match(exception)

      expect(suggestion.issue).to eq("ActionController::ParameterMissing")
      expect(suggestion.root_cause).to include("param is missing")
      expect(suggestion.fixes).to include("Check the incoming parameters and required fields")
    end

    it "matches unpermitted parameter errors" do
      exception = ActionController::UnpermittedParameters.new("found unpermitted parameter: :admin")

      suggestion = described_class.match(exception)

      expect(suggestion.issue).to eq("ActionController::UnpermittedParameters")
      expect(suggestion.root_cause).to include("found unpermitted parameter")
      expect(suggestion.fixes).to include("Whitelist allowed parameters in your strong params")
    end

    it "matches record validation errors" do
      exception = ActiveRecord::RecordInvalid.new("Validation failed: Name can't be blank")

      suggestion = described_class.match(exception)

      expect(suggestion.issue).to eq("ActiveRecord::RecordInvalid")
      expect(suggestion.root_cause).to include("Validation failed")
      expect(suggestion.fixes).to include("Check model validations and required attributes")
    end

    it "matches bad request errors" do
      exception = ActionController::BadRequest.new("Invalid request parameters")

      suggestion = described_class.match(exception)

      expect(suggestion.issue).to eq("ActionController::BadRequest")
      expect(suggestion.root_cause).to include("Invalid request")
      expect(suggestion.fixes).to include("Verify the request payload and expected format")
    end

    it "matches invalid authenticity token errors" do
      exception = ActionController::InvalidAuthenticityToken.new("Can't verify CSRF token authenticity")

      suggestion = described_class.match(exception)

      expect(suggestion.issue).to eq("ActionController::InvalidAuthenticityToken")
      expect(suggestion.root_cause).to include("CSRF")
      expect(suggestion.fixes).to include("Ensure the form includes the CSRF token")
    end

    it "matches request parsing errors" do
      exception = ActionDispatch::Http::Parameters::ParseError.new("Unexpected character")

      suggestion = described_class.match(exception)

      expect(suggestion.issue).to eq("ActionDispatch::Http::Parameters::ParseError")
      expect(suggestion.root_cause).to include("Unexpected character")
      expect(suggestion.fixes).to include("Verify the request body format and encoding")
    end

    it "matches background job deserialization errors" do
      exception = ActiveJob::DeserializationError.new("Failed to deserialize job")

      suggestion = described_class.match(exception)

      expect(suggestion.issue).to eq("ActiveJob::DeserializationError")
      expect(suggestion.root_cause).to include("deserialize")
      expect(suggestion.fixes).to include("Check job payload compatibility and serializer setup")
    end

    it "matches template rendering errors" do
      exception = ActionView::Template::Error.new("Missing template")

      suggestion = described_class.match(exception)

      expect(suggestion.issue).to eq("ActionView::Template::Error")
      expect(suggestion.root_cause).to include("Missing template")
      expect(suggestion.fixes).to include("Verify the template name and format")
    end

    it "matches missing exact template errors" do
      exception = ActionController::MissingExactTemplate.new("Missing template for this request")

      suggestion = described_class.match(exception)

      expect(suggestion.issue).to eq("ActionController::MissingExactTemplate")
      expect(suggestion.root_cause).to include("Missing template")
      expect(suggestion.fixes).to include("Add the expected template for the requested format")
    end

    it "matches missing record errors" do
      exception = ActiveRecord::RecordNotFound.new("Couldn't find Post with id=99")

      suggestion = described_class.match(exception)

      expect(suggestion.issue).to eq("ActiveRecord::RecordNotFound")
      expect(suggestion.root_cause).to include("Couldn't find Post")
      expect(suggestion.fixes).to include("Verify the record ID exists before querying")
    end

    it "matches active storage file errors" do
      exception = ActiveStorage::FileNotFoundError.new("File not found")

      suggestion = described_class.match(exception)

      expect(suggestion.issue).to eq("ActiveStorage::FileNotFoundError")
      expect(suggestion.root_cause).to include("File not found")
      expect(suggestion.fixes).to include("Verify the storage object exists and the key is correct")
    end

    it "matches redis connection errors" do
      exception = Redis::BaseError.new("Connection refused")

      suggestion = described_class.match(exception)

      expect(suggestion.issue).to eq("Redis::BaseError")
      expect(suggestion.root_cause).to include("Connection refused")
      expect(suggestion.fixes).to include("Verify the Redis connection settings and service availability")
    end

    it "matches faraday transport errors" do
      exception = Faraday::Error.new("Connection failed")

      suggestion = described_class.match(exception)

      expect(suggestion.issue).to eq("Faraday::Error")
      expect(suggestion.root_cause).to include("Connection failed")
      expect(suggestion.fixes).to include("Inspect the upstream service and network connectivity")
    end

    it "matches unknown format errors" do
      exception = ActionController::UnknownFormat.new("HTML format is not supported")

      suggestion = described_class.match(exception)

      expect(suggestion.issue).to eq("ActionController::UnknownFormat")
      expect(suggestion.root_cause).to include("HTML format")
      expect(suggestion.fixes).to include("Check the requested format and respond with a supported one")
    end

    it "matches invalid cross-origin request errors" do
      exception = ActionController::InvalidCrossOriginRequest.new("Security warning")

      suggestion = described_class.match(exception)

      expect(suggestion.issue).to eq("ActionController::InvalidCrossOriginRequest")
      expect(suggestion.root_cause).to include("Security warning")
      expect(suggestion.fixes).to include("Verify the CORS configuration and request origin")
    end

    it "matches flash errors" do
      exception = ActionDispatch::Flash::FlashError.new("Flash not available")

      suggestion = described_class.match(exception)

      expect(suggestion.issue).to eq("ActionDispatch::Flash::FlashError")
      expect(suggestion.root_cause).to include("Flash not available")
      expect(suggestion.fixes).to include("Check flash usage and session persistence")
    end

    it "matches invalid signed message errors" do
      exception = ActiveSupport::MessageVerifier::InvalidSignature.new("Signature verification failed")

      suggestion = described_class.match(exception)

      expect(suggestion.issue).to eq("ActiveSupport::MessageVerifier::InvalidSignature")
      expect(suggestion.root_cause).to include("Signature verification")
      expect(suggestion.fixes).to include("Verify the signed payload and secret rotation")
    end

    it "matches active storage integrity errors" do
      exception = ActiveStorage::IntegrityError.new("Checksum mismatch")

      suggestion = described_class.match(exception)

      expect(suggestion.issue).to eq("ActiveStorage::IntegrityError")
      expect(suggestion.root_cause).to include("Checksum mismatch")
      expect(suggestion.fixes).to include("Validate uploaded content and storage integrity")
    end
  end

  describe Bugsage::ExceptionsApp do
    it "renders a BugSage page for Rails exceptions" do
      exception = NoMethodError.new("undefined method `each' for class User")
      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/users",
        "action_dispatch.exception" => exception,
        "action_dispatch.request.path_parameters" => { "controller" => "users", "action" => "index" },
        "HTTP_HOST" => "example.test",
        "action_dispatch.request_id" => "req-999"
      }

      status, _headers, body = described_class.new.call(env)
      html = body.join

      expect(status).to eq(500)
      expect(html).to include("BugSage caught")
      expect(html).to include("NoMethodError")
      expect(html).to include("Rails Request Context")
    end
  end

  describe Bugsage::Middleware do
    let(:app) do
      lambda do |_env|
        raise NoMethodError, "undefined method `foo' for nil:NilClass"
      end
    end

    let(:env) do
      {
        "REQUEST_METHOD" => "POST",
        "PATH_INFO" => "/posts",
        "QUERY_STRING" => "draft=true",
        "HTTP_HOST" => "example.test",
        "action_dispatch.request_id" => "req-123",
        "HTTP_USER_AGENT" => "RSpec",
        "action_dispatch.request.path_parameters" => { "controller" => "posts", "action" => "create" },
        "action_dispatch.request.parameters" => { "post" => { "title" => "Hello" } }
      }
    end

    it "includes Rails request context in the rendered error page" do
      response = described_class.new(app).call(env)
      html = response[2].join

      expect(response[0]).to eq(500)
      expect(html).to include("Rails Request Context")
      expect(html).to include("POST")
      expect(html).to include("/posts")
      expect(html).to include("example.test")
      expect(html).to include("req-123")
      expect(html).to include("RSpec")
      expect(html).to include("posts")
      expect(html).to include("create")
      expect(html).to include("Hello")
    end
  end
end
