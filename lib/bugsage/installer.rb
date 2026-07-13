# frozen_string_literal: true

require "fileutils"

module Bugsage
  class Installer
    INITIALIZER_PATH = "config/initializers/bugsage.rb"
    TEMPLATE_PATH = File.expand_path("../../generators/bugsage/install/templates/bugsage.rb", __dir__)

    def self.run(destination: Dir.pwd, force: false)
      new(destination: destination, force: force).run
    end

    def initialize(destination:, force: false)
      @destination = File.expand_path(destination)
      @force = force
    end

    def run
      validate_rails_app!

      path = File.join(@destination, INITIALIZER_PATH)
      created_initializer = write_initializer(path)
      config = Bugsage::AutoConfigurator.apply!

      {
        initializer_path: path,
        created_initializer: created_initializer,
        summary: Bugsage::AutoConfigurator.summary(config)
      }
    end

    private

    def validate_rails_app!
      application_file = File.join(@destination, "config/application.rb")
      return if File.exist?(application_file)

      raise Error, "Could not find a Rails app at #{@destination}. Run this from your app root."
    end

    def write_initializer(path)
      if File.exist?(path) && !@force
        return false
      end

      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, initializer_template)
      true
    end

    def initializer_template
      if File.exist?(TEMPLATE_PATH)
        File.read(TEMPLATE_PATH)
      else
        default_initializer_template
      end
    end

    def default_initializer_template
      <<~RUBY
        # frozen_string_literal: true

        # See Bugsage::Installation or run: bundle exec bugsage install --guide-only
      RUBY
    end
  end
end
