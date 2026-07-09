# frozen_string_literal: true

unless defined?(ActionController::RoutingError)
  module ActionController
    class RoutingError < StandardError; end
    class ParameterMissing < StandardError; end
    class UnpermittedParameters < StandardError; end
  end
end

unless defined?(ActiveRecord::RecordInvalid)
  module ActiveRecord
    class RecordInvalid < StandardError; end
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
