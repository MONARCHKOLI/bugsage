# frozen_string_literal: true

require "time"

module Bugsage
  class Store
    MAX_ENTRIES = 100

    def self.add(suggestion, context = {})
      event = build_event(suggestion, context)
      entries.unshift(event)
      entries.pop if entries.size > MAX_ENTRIES
    end

    def self.all
      entries
    end

    def self.clear!
      @entries = []
    end

    def self.entries
      @entries ||= []
    end

    def self.build_event(suggestion, context)
      {
        issue: suggestion.issue,
        location: suggestion.location,
        root_cause: suggestion.root_cause,
        fixes: suggestion.fixes,
        confidence: suggestion.confidence,
        context: context,
        timestamp: Time.now.utc.iso8601
      }
    end
  end
end
