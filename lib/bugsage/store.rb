# frozen_string_literal: true

require "time"

module Bugsage
  class Store
    MAX_ENTRIES = 100

    def self.add(suggestion, context = {}, metadata = {})
      event = build_event(suggestion, context, metadata)
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

    def self.update_at(index, suggestion, ai_error: nil)
      event = entries[index]
      return unless event

      event[:root_cause] = suggestion.root_cause
      event[:fixes] = suggestion.fixes
      event[:confidence] = suggestion.confidence
      event[:source] = suggestion.source
      event[:ai_notes] = suggestion.ai_notes
      event[:code_patch] = suggestion.code_patch
      event[:ai_error] = ai_error
    end

    def self.build_event(suggestion, context, metadata = {})
      exception = metadata[:exception]

      {
        issue: suggestion.issue,
        location: suggestion.location,
        root_cause: suggestion.root_cause,
        fixes: suggestion.fixes,
        confidence: suggestion.confidence,
        source: suggestion.source,
        ai_notes: suggestion.ai_notes,
        code_patch: suggestion.code_patch,
        ai_error: metadata[:ai_error],
        exception_class: exception&.class&.name,
        exception_message: exception&.message.to_s,
        context: context,
        timestamp: Time.now.utc.iso8601
      }
    end
  end
end
