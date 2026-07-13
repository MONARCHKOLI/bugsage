# frozen_string_literal: true

module Bugsage
  # Single source of truth for installing BugSage in a Rails application.
  # Referenced by the README, install generator, CLI, and initializer template.
  module Installation
    STEPS = [
      {
        title: "Add the gem to your Gemfile",
        command: 'gem "bugsage"',
        note: "Use a git/path source while developing locally if needed."
      },
      {
        title: "Install dependencies",
        command: "bundle install",
        note: nil
      },
      {
        title: "Start your Rails server",
        command: "bin/rails server",
        note: "BugSage auto-wires via Bugsage::Railtie — no routes.rb or middleware changes required."
      },
      {
        title: "Trigger an error to verify",
        command: "Visit any route that raises an exception in development.",
        note: "You should see the BugSage error page instead of the default Rails page."
      },
      {
        title: "Open the session dashboard (optional)",
        command: "http://localhost:3000/bugsage",
        note: "Lists all errors caught during the current server session."
      }
    ].freeze

    OPTIONAL_STEPS = [
      {
        title: "Generate a commented initializer for custom overrides",
        command: "bundle exec rails generate bugsage:install",
        alternative: "bundle exec bugsage install"
      },
      {
        title: "Enable AI-enhanced suggestions (optional)",
        command: "export OPENAI_API_KEY=sk-your-key",
        alternative: "export CURSOR_API_KEY=crsr_your-key",
        note: "BugSage auto-detects the provider from the key prefix on boot."
      },
      {
        title: "Control enabled environments (optional)",
        command: "export BUGSAGE_ENABLED_ENVIRONMENTS=development,test,staging",
        note: "Defaults to development and test."
      }
    ].freeze

    AUTO_WIRED = [
      "Exception capture middleware",
      "BugSage HTML error pages in development",
      "Session dashboard at /bugsage",
      "Inline Rails console at /bugsage/console",
      "Routing error capture via exceptions_app",
      "AI provider auto-detection when API keys are present"
    ].freeze

    module_function

    def guide_lines
      lines = ["BugSage — Rails installation steps", ""]

      STEPS.each_with_index do |step, index|
        lines << "#{index + 1}. #{step[:title]}"
        lines << "   #{step[:command]}"
        lines << "   #{step[:note]}" if step[:note]
        lines << ""
      end

      lines << "Optional:"
      OPTIONAL_STEPS.each_with_index do |step, index|
        lines << "#{index + 1}. #{step[:title]}"
        lines << "   #{step[:command]}"
        lines << "   or: #{step[:alternative]}" if step[:alternative]
        lines << "   #{step[:note]}" if step[:note]
        lines << ""
      end

      lines << "Auto-wired on boot (no manual setup):"
      AUTO_WIRED.each { |item| lines << "  - #{item}" }

      lines
    end

    def print_guide
      guide_lines.each { |line| puts line }
    end
  end
end
