# frozen_string_literal: true

# BugSage Rails integration.
#
# Installation (zero-config):
#   1. gem "bugsage" in Gemfile
#   2. bundle install
#   3. bin/rails server
#
# See Bugsage::Installation for the full guide.
module Bugsage
  class Railtie < Rails::Railtie
    config.bugsage = ActiveSupport::OrderedOptions.new

    initializer "bugsage.configuration" do |app|
      Bugsage.configure do |bugsage_config|
        if app.config.bugsage.respond_to?(:each_pair)
          app.config.bugsage.each_pair do |key, value|
            bugsage_config.public_send("#{key}=", value) if bugsage_config.respond_to?("#{key}=")
          end
        end
      end

      Bugsage::AutoConfigurator.apply!
    end

    initializer "bugsage.i18n" do
      Bugsage::Translations.load!
    end

    initializer "bugsage.middleware" do |app|
      app.config.middleware.use Bugsage::Middleware
    end

    initializer "bugsage.exceptions_app" do |app|
      Bugsage.configuration.fallback_exceptions_app ||= app.config.exceptions_app
      app.config.exceptions_app = Bugsage::ExceptionsApp
    end

    initializer "bugsage.debug_interceptor" do
      ActionDispatch::DebugExceptions.register_interceptor do |request, exception|
        next unless Bugsage.configuration.enabled?
        next unless Bugsage.configuration.capture_errors?

        Bugsage::ExceptionHandler.store_exception(request.env, exception)
      end
    end
  end
end
