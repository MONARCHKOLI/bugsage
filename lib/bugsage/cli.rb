require "thor"

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