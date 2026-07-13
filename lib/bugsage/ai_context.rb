# frozen_string_literal: true

module Bugsage
  module AiContext
    module_function

    def set(exception:, suggestion:, context:)
      @exception = exception
      @suggestion = suggestion
      @context = context || {}
    end

    def load_from_event(event)
      return false unless event

      klass = safe_constantize(event[:exception_class])
      message = event[:exception_message].to_s
      message = event[:root_cause].to_s if message.empty?

      set(
        exception: klass.new(message),
        suggestion: suggestion_from_event(event),
        context: event[:context] || {}
      )
      true
    end

    def clear!
      @exception = nil
      @suggestion = nil
      @context = {}
    end

    def available?
      !@exception.nil? && !@suggestion.nil?
    end

    def current
      return nil unless available?

      {
        exception: @exception,
        suggestion: @suggestion,
        context: @context
      }
    end

    def suggestion_from_event(event)
      Suggestion.new(
        issue: event[:issue],
        location: event[:location],
        root_cause: event[:root_cause],
        fixes: event[:fixes] || [],
        confidence: event[:confidence],
        source: event[:source] || :rules,
        ai_notes: event[:ai_notes],
        code_patch: event[:code_patch]
      )
    end

    def safe_constantize(name)
      return StandardError if name.to_s.strip.empty?

      Object.const_get(name)
    rescue NameError
      StandardError
    end
  end
end
