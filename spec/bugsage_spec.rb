# frozen_string_literal: true

require "tempfile"
require "stringio"
require "fileutils"
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
    class ActiveRecordError < StandardError; end
    class RecordInvalid < ActiveRecordError; end
    class RecordNotFound < ActiveRecordError; end
    class StatementInvalid < ActiveRecordError; end
    class RecordNotUnique < StatementInvalid; end
    class NotNullViolation < StatementInvalid; end
    class ConnectionNotEstablished < ActiveRecordError; end
    class StaleObjectError < ActiveRecordError; end
  end
end

unless defined?(PG::Error)
  module PG
    class Error < StandardError; end
    class UniqueViolation < Error; end
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
    before do
      ENV["RAILS_ENV"] = "development"
      Bugsage.configure do |config|
        config.show_error_page = true
        config.capture_errors = true
      end
    end

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

    it "renders a BugSage page for routing errors with a 404 status" do
      exception = ActionController::RoutingError.new('No route matches [GET] "/us"')
      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/us",
        "action_dispatch.exception" => exception,
        "HTTP_HOST" => "example.test"
      }

      Bugsage::Store.clear!
      status, _headers, body = described_class.call(env)
      html = body.join

      expect(status).to eq(404)
      expect(html).to include("ActionController::RoutingError")
      expect(html).to include("/us")
      expect(Bugsage::Store.all.first[:issue]).to eq("ActionController::RoutingError")
    end
  end

  describe Bugsage::Dashboard do
    let(:event) do
      {
        issue: "NoMethodError",
        location: "#{__FILE__}:1",
        root_cause: "undefined method `foo'",
        fixes: ["Check object initialization"],
        confidence: 95,
        context: { "Path" => "/posts", "Request method" => "POST" },
        timestamp: "2026-07-09T12:00:00Z"
      }
    end

    it "renders a split layout with a bug list and detail panel" do
      html = described_class.render([event])

      expect(html).to include("BugSage")
      expect(html).to include('class="sidebar"')
      expect(html).to include('class="detail-panel"')
      expect(html).to include('class="bug-item active"')
      expect(html).to include('id="bug-0"')
      expect(html).to include("Suggested fixes")
      expect(html).to include("Rails request context")
      expect(html).to include("code-line error")
      expect(html).to include("/posts")
      expect(html).to include("data-bug-id=\"bug-0\"")
    end
  end

  describe Bugsage::Configuration do
    it "enables BugSage in development and test by default" do
      config = described_class.new

      expect(config.enabled?("development")).to be true
      expect(config.enabled?("test")).to be true
      expect(config.enabled?("production")).to be false
    end

    it "shows the error page only in development by default" do
      config = described_class.new

      expect(config.show_error_page?("development")).to be true
      expect(config.show_error_page?("test")).to be false
      expect(config.show_error_page?("production")).to be false
    end

    it "shows the dashboard only in development by default" do
      config = described_class.new

      expect(config.show_dashboard?("development")).to be true
      expect(config.show_dashboard?("test")).to be false
    end

    it "shows the inline console only in development by default" do
      config = described_class.new

      expect(config.show_inline_console?("development")).to be true
      expect(config.show_inline_console?("test")).to be false
    end

    it "allows custom configuration through Bugsage.configure" do
      Bugsage.configure do |config|
        config.enabled_environments = %i[development production]
        config.show_error_page = true
        config.ai_enabled = true
      end

      expect(Bugsage.configuration.enabled?("production")).to be true
      expect(Bugsage.configuration.show_error_page?("production")).to be true
      expect(Bugsage.configuration.ai_enabled?("production")).to be true
    end

    it "requires an API key before AI is considered configured" do
      config = described_class.new
      config.ai_enabled = true

      expect(config.ai_configured?("development")).to be false

      config.openai_api_key = "test-key"

      expect(config.ai_configured?("development")).to be true
    end

    it "treats a custom ai_client as configured without an API key" do
      config = described_class.new
      config.ai_enabled = true
      config.ai_client = Object.new

      expect(config.ai_configured?("development")).to be true
    end

    it "resolves the OpenAI API key from environment variables" do
      config = described_class.new
      ENV["BUGSAGE_OPENAI_API_KEY"] = "env-key"

      expect(config.resolved_openai_api_key).to eq("env-key")
    ensure
      ENV.delete("BUGSAGE_OPENAI_API_KEY")
    end

    it "auto-detects Cursor when a crsr_ key is exported as OPENAI_API_KEY" do
      config = described_class.new
      config.ai_enabled = true
      config.openai_api_key = "crsr_test_cursor_key"

      expect(config.resolved_ai_provider).to eq(:cursor)
      expect(config.resolved_cursor_api_key).to eq("crsr_test_cursor_key")
      expect(config.resolved_openai_api_key).to be_nil
      expect(config.ai_configured?("development")).to be true
    end

    it "uses a longer effective timeout for Cursor" do
      config = described_class.new
      config.ai_provider = :cursor
      config.ai_timeout = 15

      expect(config.effective_ai_timeout).to eq(90)
    end

    it "keeps AI off by default when no API key is present" do
      config = described_class.new

      expect(config.ai_enabled).to be_nil
      expect(config.ai_enabled?("development")).to be false
    end

    describe "#ignored_path?" do
      it "ignores /favicon.ico by default" do
        config = described_class.new

        expect(config.ignored_path?("/favicon.ico")).to be true
      end

      it "ignores asset pipeline paths by default" do
        config = described_class.new

        expect(config.ignored_path?("/assets/application.js")).to be true
        expect(config.ignored_path?("/packs/main-abc123.js")).to be true
        expect(config.ignored_path?("/vite/assets/app.js")).to be true
      end

      it "does not ignore normal application paths" do
        config = described_class.new

        expect(config.ignored_path?("/users")).to be false
        expect(config.ignored_path?("/boom")).to be false
        expect(config.ignored_path?("/")).to be false
      end

      it "accepts custom string paths" do
        config = described_class.new
        config.ignored_paths = ["/health", "/robots.txt"]

        expect(config.ignored_path?("/health")).to be true
        expect(config.ignored_path?("/robots.txt")).to be true
        expect(config.ignored_path?("/favicon.ico")).to be false
      end

      it "accepts custom regex patterns" do
        config = described_class.new
        config.ignored_paths = [%r{\A/api/healthz}]

        expect(config.ignored_path?("/api/healthz")).to be true
        expect(config.ignored_path?("/api/users")).to be false
      end
    end
  end

  describe Bugsage::AutoConfigurator do
    it "enables AI when an OpenAI key is present in the environment" do
      config = Bugsage::Configuration.new
      env = { "OPENAI_API_KEY" => "sk-test-openai-key" }

      described_class.apply!(config, env: env)

      expect(config.ai_enabled).to be true
      expect(config.resolved_ai_provider).to eq(:openai)
      expect(config.ai_enabled?("development")).to be true
    end

    it "enables Cursor when a crsr_ key is exported as OPENAI_API_KEY" do
      config = Bugsage::Configuration.new
      env = { "OPENAI_API_KEY" => "crsr_test_cursor_key" }

      described_class.apply!(config, env: env)

      expect(config.ai_enabled).to be true
      expect(config.resolved_ai_provider).to eq(:cursor)
      expect(config.cursor_api_key).to eq("crsr_test_cursor_key")
    end

    it "does not override an explicit ai_enabled = false" do
      config = Bugsage::Configuration.new
      config.ai_enabled = false
      env = { "OPENAI_API_KEY" => "sk-test-openai-key" }

      described_class.apply!(config, env: env)

      expect(config.ai_enabled).to be false
      expect(config.ai_enabled?("development")).to be false
    end

    it "applies enabled environments from BUGSAGE_ENABLED_ENVIRONMENTS" do
      config = Bugsage::Configuration.new
      env = { "BUGSAGE_ENABLED_ENVIRONMENTS" => "development,staging" }

      described_class.apply!(config, env: env)

      expect(config.enabled_environments).to eq(%i[development staging])
    end
  end

  describe Bugsage::Installation do
    it "documents the Rails install steps" do
      guide = described_class.guide_lines.join("\n")

      expect(described_class::STEPS.length).to eq(5)
      expect(guide).to include('gem "bugsage"')
      expect(guide).to include("bundle install")
      expect(guide).to include("/bugsage")
      expect(guide).to include("OPENAI_API_KEY")
    end
  end

  describe Bugsage::Installer do
    it "creates an initializer in a Rails app directory" do
      Dir.mktmpdir do |root|
        FileUtils.mkdir_p(File.join(root, "config"))
        File.write(File.join(root, "config/application.rb"), "class Application < Rails::Application; end\n")

        result = described_class.run(destination: root)

        expect(result[:created_initializer]).to be true
        expect(File).to exist(File.join(root, "config/initializers/bugsage.rb"))
        expect(result[:summary].join).to include("BugSage is ready to use.")
      end
    end

    it "raises when the destination is not a Rails app" do
      Dir.mktmpdir do |root|
        expect { described_class.run(destination: root) }
          .to raise_error(Bugsage::Error, /Could not find a Rails app/)
      end
    end
  end

  describe Bugsage::Suggestion do
    it "tracks whether a suggestion was AI-enhanced" do
      suggestion = described_class.new(
        issue: "NoMethodError",
        location: "app.rb:1",
        root_cause: "nil receiver",
        fixes: ["Add nil guard"],
        confidence: 95,
        source: :hybrid,
        ai_notes: "Check initialization order."
      )

      expect(suggestion.ai_enhanced?).to be true
      expect(suggestion.source).to eq(:hybrid)
      expect(suggestion.ai_notes).to eq("Check initialization order.")
    end
  end

  describe Bugsage::AiAnalyzer do
    let(:base_suggestion) do
      Bugsage::Suggestion.new(
        issue: "NoMethodError",
        location: "app/models/user.rb:12",
        root_cause: "undefined method `name' for nil",
        fixes: ["Add nil guard"],
        confidence: 95
      )
    end

    let(:exception) { NoMethodError.new("undefined method `name' for nil:NilClass") }

    let(:mock_client) do
      Class.new do
        def complete(system_prompt:, user_prompt:)
          JSON.generate(
            root_cause: "The user object was nil before calling name.",
            fixes: ["Initialize @user before the action runs", "Add nil guard"],
            confidence: 92,
            notes: "This often happens when a before_action lookup fails silently."
          )
        end
      end.new
    end

    it "returns the rule suggestion when AI is disabled" do
      Bugsage.configure { |config| config.ai_enabled = false }

      result, ai_error = described_class.enhance(base_suggestion, exception, {}, client: mock_client)

      expect(result).to equal(base_suggestion)
      expect(result.source).to eq(:rules)
      expect(ai_error).to be_nil
    end

    it "returns the rule suggestion when no API key is configured" do
      Bugsage.configure do |config|
        config.ai_enabled = true
        config.openai_api_key = nil
      end
      ENV.delete("OPENAI_API_KEY")
      ENV.delete("BUGSAGE_OPENAI_API_KEY")

      result, ai_error = described_class.enhance(base_suggestion, exception, {}, client: mock_client)

      expect(result).to equal(base_suggestion)
      expect(ai_error).to be_nil
    end

    it "merges AI output into the rule suggestion when configured" do
      Bugsage.configure do |config|
        config.ai_enabled = true
        config.openai_api_key = "test-key"
      end

      result, ai_error = described_class.enhance(base_suggestion, exception, {}, client: mock_client)

      expect(result.source).to eq(:hybrid)
      expect(result.root_cause).to include("user object was nil")
      expect(result.fixes.first).to eq("Initialize @user before the action runs")
      expect(result.fixes).to include("Add nil guard")
      expect(result.confidence).to eq(92)
      expect(result.ai_notes).to include("before_action")
      expect(ai_error).to be_nil
    end

    it "falls back to the rule suggestion when the AI client fails" do
      failing_client = Class.new do
        def complete(**)
          raise Bugsage::Error, "API unavailable"
        end
      end.new

      Bugsage.configure do |config|
        config.ai_enabled = true
        config.openai_api_key = "test-key"
      end

      result, ai_error = described_class.enhance(base_suggestion, exception, {}, client: failing_client)

      expect(result).to equal(base_suggestion)
      expect(result.source).to eq(:rules)
      expect(ai_error).to eq("API unavailable")
    end

    it "parses JSON wrapped in markdown fences" do
      Bugsage.configure do |config|
        config.ai_enabled = true
        config.openai_api_key = "test-key"
      end

      markdown_client = Class.new do
        def complete(system_prompt:, user_prompt:)
          <<~JSON
            ```json
            {
              "root_cause": "Markdown wrapped response",
              "fixes": ["Fix from markdown"],
              "confidence": 88,
              "notes": "Parsed successfully"
            }
            ```
          JSON
        end
      end.new

      result, ai_error = described_class.enhance(base_suggestion, exception, {}, client: markdown_client)

      expect(result.source).to eq(:hybrid)
      expect(result.root_cause).to eq("Markdown wrapped response")
      expect(ai_error).to be_nil
    end

    it "selects the Cursor client when a crsr_ key is configured" do
      analyzer = described_class.new(
        config: Bugsage::Configuration.new.tap do |config|
          config.ai_enabled = true
          config.cursor_api_key = "crsr_test"
        end
      )

      expect(analyzer.send(:build_client)).to be_a(Bugsage::CursorClient)
    end
  end

  describe "AI-enhanced exception handling" do
    around do |example|
      original = ENV.fetch("RAILS_ENV", nil)
      ENV["RAILS_ENV"] = "development"
      example.run
    ensure
      if original
        ENV["RAILS_ENV"] = original
      else
        ENV.delete("RAILS_ENV")
      end
    end

    let(:mock_client) do
      Class.new do
        def complete(system_prompt:, user_prompt:)
          if system_prompt.include?("chatting with a developer")
            JSON.generate(
              reply: "Commenting out the line is safer than deleting it.",
              code_patch: {
                action: "replace_lines",
                start_line: 10,
                end_line: 10,
                replacement: '# raise "Hiii"'
              }
            )
          else
            JSON.generate(
              root_cause: "AI says the receiver was nil.",
              fixes: ["AI fix"],
              confidence: 91,
              notes: "AI notes here.",
              code_patch: {
                action: "delete_lines",
                start_line: 10,
                end_line: 10,
                replacement: ""
              }
            )
          end
        end
      end.new
    end

    before do
      Bugsage.configure do |config|
        config.show_error_page = true
        config.capture_errors = true
        config.ai_enabled = true
        config.openai_api_key = "test-key"
        config.ai_client = mock_client
      end
    end

    it "does not call AI automatically during exception rendering" do
      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/users",
        "HTTP_HOST" => "example.test"
      }
      exception = NoMethodError.new("undefined method `foo' for nil:NilClass")

      Bugsage::Store.clear!
      status, _headers, body = Bugsage::ExceptionHandler.render_response(env, exception)
      html = body.join

      stored = Bugsage::Store.all.first
      expect(status).to eq(500)
      expect(stored[:source]).to eq(:rules)
      expect(stored[:ai_notes]).to be_nil
      expect(html).to include("Quick Fix Suggestion")
      expect(html).to include("bugsage-ai-chat-toggle")
      expect(html).to include("bugsage-ai-loading")
      expect(html).not_to include("AI-enhanced analysis")
    end

    it "returns AI-enhanced suggestions when Quick Fix is requested" do
      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/users",
        "HTTP_HOST" => "example.test"
      }
      exception = NoMethodError.new("undefined method `foo' for nil:NilClass")

      Bugsage::Store.clear!
      Bugsage::ExceptionHandler.render_response(env, exception)

      request_env = {
        "REQUEST_METHOD" => "POST",
        "PATH_INFO" => "/bugsage/ai-suggest",
        "rack.input" => StringIO.new("{}")
      }

      status, headers, body = Bugsage::Middleware.new(->(_env) { [404, {}, []] }).call(request_env)
      payload = JSON.parse(body.join)

      expect(status).to eq(200)
      expect(headers["Content-Type"]).to eq("application/json")
      expect(payload["ok"]).to be true
      expect(payload["ai_enhanced"]).to be true
      expect(payload["ai_notes"]).to eq("AI notes here.")
      expect(payload["code_patch"]["action"]).to eq("delete_lines")
      expect(payload["code_fix"]).to include("remove line 10")
      expect(Bugsage::Store.all.first[:source]).to eq(:hybrid)
    end

    it "returns chat replies for follow-up questions" do
      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/users",
        "HTTP_HOST" => "example.test"
      }
      exception = NoMethodError.new("undefined method `foo' for nil:NilClass")

      Bugsage::Store.clear!
      Bugsage::ExceptionHandler.render_response(env, exception)

      request_env = {
        "REQUEST_METHOD" => "POST",
        "PATH_INFO" => "/bugsage/ai-chat",
        "rack.input" => StringIO.new(
          JSON.generate(message: "Why should we delete that line?")
        )
      }

      status, headers, body = Bugsage::Middleware.new(->(_env) { [404, {}, []] }).call(request_env)
      payload = JSON.parse(body.join)

      expect(status).to eq(200)
      expect(headers["Content-Type"]).to eq("application/json")
      expect(payload["ok"]).to be true
      expect(payload["reply"]).to include("Commenting out")
      expect(payload["code_patch"]["action"]).to eq("replace_lines")
      expect(payload["code_fix"]).to include("replace line 10")
      expect(payload["history"].last["role"]).to eq("assistant")
      expect(Bugsage::Store.all.first[:code_patch][:action]).to eq("replace_lines")
    end
  end

  describe Bugsage::Middleware do
    around do |example|
      original = ENV.fetch("RAILS_ENV", nil)
      ENV["RAILS_ENV"] = "development"
      example.run
    ensure
      if original
        ENV["RAILS_ENV"] = original
      else
        ENV.delete("RAILS_ENV")
      end
    end
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

    it "captures routing errors handled internally by Rails" do
      rails_app = lambda do |inner_env|
        inner_env["action_dispatch.exception"] =
          ActionController::RoutingError.new('No route matches [GET] "/abchac"')
        [404, { "Content-Type" => "text/html" }, ["Rails routing error page"]]
      end

      routing_env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/abchac",
        "HTTP_HOST" => "example.test"
      }

      Bugsage::Store.clear!
      response = described_class.new(rails_app).call(routing_env)
      html = response[2].join

      expect(response[0]).to eq(404)
      expect(html).to include("BugSage caught")
      expect(html).to include("ActionController::RoutingError")
      expect(html).to include("No route matches [GET]")
      expect(html).to include("/abchac")
      expect(Bugsage::Store.all.first[:issue]).to eq("ActionController::RoutingError")
    end

    it "captures routing errors returned with X-Cascade pass" do
      rails_app = ->(_env) { [404, { "X-Cascade" => "pass" }, []] }
      routing_env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/us",
        "HTTP_HOST" => "example.test"
      }

      Bugsage::Store.clear!
      response = described_class.new(rails_app).call(routing_env)
      html = response[2].join

      expect(response[0]).to eq(404)
      expect(html).to include("BugSage caught")
      expect(Bugsage::Store.all.first[:issue]).to eq("ActionController::RoutingError")
    end

    it "does not capture routing errors for ignored paths like /favicon.ico" do
      rails_app = ->(_env) { [404, { "X-Cascade" => "pass" }, []] }
      favicon_env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/favicon.ico",
        "HTTP_HOST" => "example.test"
      }

      Bugsage::Store.clear!
      response = described_class.new(rails_app).call(favicon_env)

      expect(response[0]).to eq(404)
      expect(response[2].join).not_to include("BugSage caught")
      expect(Bugsage::Store.all).to be_empty
    end

    it "does not capture routing errors for asset pipeline paths" do
      rails_app = ->(_env) { [404, { "X-Cascade" => "pass" }, []] }
      asset_env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/assets/missing-file.js",
        "HTTP_HOST" => "example.test"
      }

      Bugsage::Store.clear!
      response = described_class.new(rails_app).call(asset_env)

      expect(response[0]).to eq(404)
      expect(Bugsage::Store.all).to be_empty
    end

    it "stores errors without rendering the error page in test mode" do
      ENV["RAILS_ENV"] = "test"

      Bugsage.configure do |config|
        config.enabled_environments = %i[test]
        config.show_error_page = false
        config.show_dashboard = false
        config.capture_errors = true
      end

      app = ->(_env) { raise NoMethodError, "undefined method `foo' for nil:NilClass" }

      Bugsage::Store.clear!
      expect do
        described_class.new(app).call(
          "REQUEST_METHOD" => "GET",
          "PATH_INFO" => "/posts",
          "HTTP_HOST" => "example.test"
        )
      end.to raise_error(NoMethodError)

      expect(Bugsage::Store.all.first[:issue]).to eq("NoMethodError")
    end

    it "does not store duplicate entries when env is already marked as captured" do
      Bugsage.configure do |config|
        config.show_error_page = false
        config.capture_errors = true
      end

      app = lambda do |env|
        env["action_dispatch.exception"] = ActiveRecord::RecordNotFound.new("Couldn't find User with 'id'=9999")
        env["bugsage.captured"] = true
        [404, { "Content-Type" => "text/html" }, ["Not Found"]]
      end

      Bugsage::Store.clear!
      described_class.new(app).call(
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/users/9999",
        "HTTP_HOST" => "example.test"
      )

      expect(Bugsage::Store.all.size).to eq(0)
    end
  end

  describe "integration capture" do
    before do
      ENV["RAILS_ENV"] = "development"
      Bugsage.configure do |config|
        config.show_error_page = true
        config.show_dashboard = true
        config.capture_errors = true
      end
    end

    ExceptionScenarios::SCENARIOS.each do |scenario|
      it "matches and stores #{scenario[:name]} through ExceptionsApp" do
        exception = scenario[:exception].call
        env = {
          "REQUEST_METHOD" => "GET",
          "PATH_INFO" => "/bugsage-test",
          "HTTP_HOST" => "example.test",
          "action_dispatch.exception" => exception
        }

        Bugsage::Store.clear!
        status, _headers, body = Bugsage::ExceptionsApp.call(env)
        html = body.join

        expect(status).to eq(scenario[:status])
        expect(html).to include("BugSage caught")
        expect(html).to include(scenario[:issue])
        expect(Bugsage::Store.all.length).to eq(1)
        expect(Bugsage::Store.all.first[:issue]).to eq(scenario[:issue])
      end

      it "matches #{scenario[:name]} through Middleware rescue path" do
        exception = scenario[:exception].call
        app = ->(_env) { raise exception }

        Bugsage::Store.clear!
        status, _headers, body = Bugsage::Middleware.new(app).call(
          "REQUEST_METHOD" => "GET",
          "PATH_INFO" => "/bugsage-test",
          "HTTP_HOST" => "example.test"
        )
        html = body.join

        expect(status).to eq(scenario[:status])
        expect(html).to include("BugSage caught")
        expect(Bugsage::Store.all.first[:issue]).to eq(scenario[:issue])
      end
    end

    it "unwraps Rails-style exception wrappers before matching" do
      inner = ActionController::RoutingError.new('No route matches [GET] "/wrapped"')
      wrapper = Class.new do
        def initialize(exception)
          @exception = exception
        end

        def unwrapped_exception
          @exception
        end
      end.new(inner)

      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/wrapped",
        "action_dispatch.exception" => wrapper
      }

      Bugsage::Store.clear!
      status, _headers, body = Bugsage::ExceptionsApp.call(env)

      expect(status).to eq(404)
      expect(Bugsage::Store.all.first[:issue]).to eq("ActionController::RoutingError")
      expect(body.join).to include("BugSage caught")
    end
  end

  describe Bugsage::InlineConsole do
    before do
      Bugsage::ConsoleContext.set(
        exception: NoMethodError.new("undefined method `name' for nil"),
        context: { "Request parameters" => { "id" => "1" } }
      )
    end

    it "evaluates Ruby with access to the current exception" do
      result = described_class.evaluate("exception.class.name")

      expect(result[:ok]).to be true
      expect(result[:output]).to include("NoMethodError")
    end

    it "exposes request params in the console binding" do
      result = described_class.evaluate("params['id']")

      expect(result[:ok]).to be true
      expect(result[:output]).to include("1")
    end

    it "returns syntax errors without raising" do
      result = described_class.evaluate("def broken")

      expect(result[:ok]).to be false
      expect(result[:output]).to include("SyntaxError")
    end
  end

  describe Bugsage::ErrorPage do
    it "includes the inline console below the error message in development by default" do
      suggestion = Bugsage::Suggestion.new(
        issue: "NoMethodError",
        location: "app/models/user.rb:12",
        root_cause: "undefined method `name' for nil",
        fixes: ["Add nil guard"],
        confidence: 95
      )

      ENV["RAILS_ENV"] = "development"
      Bugsage.reset_configuration!

      html = described_class.render(suggestion)
      message_index = html.index("Error Message:")
      console_index = html.index("Inline Rails Console")

      expect(html).to include("Inline Rails Console")
      expect(html).to include("/bugsage/console")
      expect(console_index).to be > message_index
    ensure
      ENV.delete("RAILS_ENV")
    end
  end

  describe Bugsage::Dashboard do
    it "includes the inline console in each error detail panel" do
      ENV["RAILS_ENV"] = "development"
      Bugsage.reset_configuration!

      events = [{
        issue: "NoMethodError",
        location: "app/models/user.rb:12",
        root_cause: "undefined method `name' for nil",
        fixes: ["Add nil guard"],
        confidence: 95,
        exception_class: "NoMethodError",
        exception_message: "undefined method `name' for nil",
        context: { "Request parameters" => { "id" => "1" } },
        timestamp: "2026-07-13T00:00:00Z"
      }]

      html = described_class.render(events)

      expect(html).to include("Inline Rails Console")
      expect(html).to include('data-bug-index="0"')
      expect(html).to include("bugsage-console-output-bug-0")
    ensure
      ENV.delete("RAILS_ENV")
    end
  end

  describe "inline console middleware" do
    around do |example|
      original = ENV.fetch("RAILS_ENV", nil)
      ENV["RAILS_ENV"] = "development"
      example.run
    ensure
      if original
        ENV["RAILS_ENV"] = original
      else
        ENV.delete("RAILS_ENV")
      end
    end

    it "handles POST /bugsage/console requests using a stored event index" do
      Bugsage.configure do |config|
        config.show_inline_console = true
      end

      Bugsage::Store.clear!
      Bugsage::Store.add(
        Bugsage::Suggestion.new(
          issue: "NoMethodError",
          location: "app/models/user.rb:12",
          root_cause: "undefined method `foo' for nil",
          fixes: ["Add nil guard"],
          confidence: 95
        ),
        { "Request parameters" => { "id" => "1" } },
        exception: NoMethodError.new("undefined method `foo' for nil")
      )

      env = {
        "REQUEST_METHOD" => "POST",
        "PATH_INFO" => "/bugsage/console",
        "rack.input" => StringIO.new('{"code":"params[\\"id\\"]","index":0}')
      }

      status, headers, body = Bugsage::Middleware.new(->(_env) { [404, {}, []] }).call(env)
      payload = JSON.parse(body.join)

      expect(status).to eq(200)
      expect(headers["Content-Type"]).to eq("application/json")
      expect(payload["ok"]).to be true
      expect(payload["output"]).to include("1")
    end
  end

  describe Bugsage::FixApplicator do
    it "inserts a BugSage comment above the failing line in development" do
      Dir.mktmpdir do |root|
        file = File.join(root, "sample.rb")
        File.write(file, "value = nil\nvalue.name\n")

        result = described_class.apply(
          location: "#{file}:2",
          fix: "Add a nil guard before calling name"
        )

        expect(result[:ok]).to be true
        expect(File.read(file)).to include("# BUGSAGE: Add a nil guard before calling name")
      end
    end

    it "replaces the failing line with an AI code fix" do
      Dir.mktmpdir do |root|
        file = File.join(root, "sample.rb")
        File.write(file, "  value = nil\n  value.name\n")

        result = described_class.apply(
          location: "#{file}:2",
          code_patch: {
            action: "replace_lines",
            start_line: 2,
            end_line: 2,
            replacement: "value&.name"
          }
        )

        expect(result[:ok]).to be true
        expect(File.read(file)).to include("  value&.name")
        expect(File.read(file)).not_to include("value.name\n")
      end
    end

    it "deletes stray lines suggested by AI" do
      Dir.mktmpdir do |root|
        file = File.join(root, "sample.rb")
        File.write(file, "  @user = User.find(params[:id])\n  render plain: @user.email\n\n  raise \"Hiii\"\n")

        result = described_class.apply(
          location: "#{file}:4",
          code_patch: {
            action: "delete_lines",
            start_line: 4,
            end_line: 4,
            replacement: ""
          }
        )

        expect(result[:ok]).to be true
        contents = File.read(file)
        expect(contents).not_to include('raise "Hiii"')
        expect(contents).to include("@user = User.find(params[:id])")
      end
    end

    it "rejects duplicate code already present in the file" do
      Dir.mktmpdir do |root|
        file = File.join(root, "sample.rb")
        File.write(file, "  @user = User.find(params[:id])\n  raise \"Hiii\"\n")

        result = described_class.apply(
          location: "#{file}:2",
          code_patch: {
            action: "replace_lines",
            start_line: 2,
            end_line: 2,
            replacement: "@user = User.find(params[:id])"
          }
        )

        expect(result[:ok]).to be false
        expect(result[:error]).to include("already exists")
      end
    end
  end

  describe Bugsage::CodePatch do
    it "previews delete_line patches" do
      patch = described_class.new(action: "delete_lines", start_line: 10, end_line: 10)
      expect(patch.preview).to include("remove line 10")
    end
  end

  describe "session actions middleware" do
    around do |example|
      original = ENV.fetch("RAILS_ENV", nil)
      ENV["RAILS_ENV"] = "development"
      example.run
    ensure
      if original
        ENV["RAILS_ENV"] = original
      else
        ENV.delete("RAILS_ENV")
      end
    end

    it "clears stored session logs" do
      Bugsage::Store.add(
        Bugsage::Suggestion.new(
          issue: "NoMethodError",
          location: "app.rb:1",
          root_cause: "nil receiver",
          fixes: ["Add nil guard"],
          confidence: 90
        )
      )

      env = {
        "REQUEST_METHOD" => "POST",
        "PATH_INFO" => "/bugsage/clear",
        "HTTP_ACCEPT" => "application/json",
        "rack.input" => StringIO.new("{}")
      }

      status, _headers, body = Bugsage::Middleware.new(->(_env) { [404, {}, []] }).call(env)
      payload = JSON.parse(body.join)

      expect(status).to eq(200)
      expect(payload["ok"]).to be true
      expect(Bugsage::Store.all).to be_empty
    end

    it "applies a fix through the middleware endpoint" do
      Dir.mktmpdir do |root|
        file = File.join(root, "sample.rb")
        File.write(file, "value = nil\nvalue.name\n")

        env = {
          "REQUEST_METHOD" => "POST",
          "PATH_INFO" => "/bugsage/apply-fix",
          "rack.input" => StringIO.new({
            location: "#{file}:2",
            fix: "Guard against nil before calling name"
          }.to_json)
        }

        status, _headers, body = Bugsage::Middleware.new(->(_env) { [404, {}, []] }).call(env)
        payload = JSON.parse(body.join)

        expect(status).to eq(200)
        expect(payload["ok"]).to be true
        expect(File.read(file)).to include("# BUGSAGE: Guard against nil before calling name")
      end
    end

    it "captures API bad request responses with a Rack-style body" do
      original = ENV.fetch("RAILS_ENV", nil)
      ENV["RAILS_ENV"] = "development"

      Bugsage.configure do |config|
        config.show_error_page = false
        config.capture_errors = true
        config.capture_http_errors = true
      end

      rack_body = Class.new do
        def initialize(parts)
          @parts = parts
        end

        def each(&block)
          @parts.each(&block)
        end

        def close; end
      end

      api_app = lambda do |env|
        env["action_dispatch.request.path_parameters"] = {
          controller: "api/v1/auth",
          action: "login"
        }
        [400, { "Content-Type" => "application/json" }, rack_body.new(['{"error":"invalid credentials"}'])]
      end

      env = {
        "REQUEST_METHOD" => "POST",
        "PATH_INFO" => "/api/v1/auth/login",
        "HTTP_HOST" => "example.test"
      }

      Bugsage::Store.clear!
      status, headers, body = Bugsage::Middleware.new(api_app).call(env)
      stored = Bugsage::Store.all.first

      expect(status).to eq(400)
      expect(headers["Content-Type"]).to eq("application/json")
      expect(body.join).to include("invalid credentials")
      expect(stored[:issue]).to eq("HTTP 400 Response")
      expect(stored[:location]).to eq("Api::V1::AuthController#login")
      expect(stored[:root_cause]).to include("invalid credentials")
    ensure
      if original
        ENV["RAILS_ENV"] = original
      else
        ENV.delete("RAILS_ENV")
      end
    end

    it "captures API bad request responses without raising an exception" do
      original = ENV.fetch("RAILS_ENV", nil)
      ENV["RAILS_ENV"] = "development"

      Bugsage.configure do |config|
        config.show_error_page = false
        config.capture_errors = true
        config.capture_http_errors = true
      end

      api_app = lambda do |env|
        env["action_dispatch.request.path_parameters"] = {
          controller: "api/v1/auth",
          action: "login"
        }
        [400, { "Content-Type" => "application/json" }, ['{"error":"email is required"}']]
      end

      env = {
        "REQUEST_METHOD" => "POST",
        "PATH_INFO" => "/api/v1/auth/login",
        "HTTP_HOST" => "example.test"
      }

      Bugsage::Store.clear!
      status, headers, body = Bugsage::Middleware.new(api_app).call(env)
      stored = Bugsage::Store.all.first

      expect(status).to eq(400)
      expect(headers["Content-Type"]).to eq("application/json")
      expect(body.join).to include("email is required")
      expect(stored[:issue]).to eq("HTTP 400 Response")
      expect(stored[:location]).to eq("Api::V1::AuthController#login")
      expect(stored[:root_cause]).to include("email is required")
    ensure
      if original
        ENV["RAILS_ENV"] = original
      else
        ENV.delete("RAILS_ENV")
      end
    end
  end

  describe Bugsage::HttpErrorCapture do
    it "builds an HTTP response error from controller context and JSON body" do
      env = {
        "PATH_INFO" => "/api/v1/auth/login",
        "action_dispatch.request.path_parameters" => {
          "controller" => "api/v1/auth",
          "action" => "login"
        }
      }

      exception = described_class.build_exception(
        env,
        400,
        '{"error":"email is required"}'
      )

      expect(exception).to be_a(Bugsage::HttpResponseError)
      expect(exception.status).to eq(400)
      expect(exception.location).to eq("Api::V1::AuthController#login")
      expect(exception.message).to include("email is required")
    end
  end
end
