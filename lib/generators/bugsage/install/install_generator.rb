# frozen_string_literal: true

require "rails/generators/base"

module Bugsage
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Install BugSage configuration (optional initializer)"
      source_root File.expand_path("templates", __dir__)

      def copy_initializer
        template "bugsage.rb", "config/initializers/bugsage.rb"
      end

      def show_summary
        config = Bugsage::AutoConfigurator.apply!
        say "\n#{Bugsage::AutoConfigurator.summary(config).join("\n")}\n", :green
      end
    end
  end
end
