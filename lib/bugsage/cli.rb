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
  end
end