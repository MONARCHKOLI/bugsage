# frozen_string_literal: true

require "thor"
require "fileutils"

module Bugsage
  class CLI < Thor
    desc "version", "Print BugSage version"
    def version
      puts "BugSage v#{Bugsage::VERSION}"
    end

    desc "hello", "Sanity check command"
    def hello
      puts "BugSage is alive."
    end

    desc "install", "Print install steps and generate config/initializers/bugsage.rb"
    option :destination, aliases: "-d", desc: "Rails app root directory"
    option :force, type: :boolean, default: false, desc: "Overwrite an existing initializer"
    option :guide_only, type: :boolean, default: false, desc: "Print installation steps without writing files"
    def install
      if options[:guide_only]
        Installation.print_guide
        return
      end

      Installation.print_guide
      say ""

      result = Installer.run(destination: options[:destination] || Dir.pwd, force: options[:force])

      if result[:created_initializer]
        say "Created #{result[:initializer_path]}", :green
      else
        say "Skipped #{result[:initializer_path]} (already exists). Use --force to overwrite.", :yellow
      end

      say "\n#{result[:summary].join("\n")}\n"
    end

    desc "explain", "Run a fake exception through the rule engine (demo)"
    def explain
      fake_exception = begin
        nil.foo
      rescue NoMethodError => e
        e
      end

      suggestion = Rule.match(fake_exception)

      if suggestion
        Formatter.print(suggestion)
      else
        puts "No matching rule found."
      end
    end
  end
end
