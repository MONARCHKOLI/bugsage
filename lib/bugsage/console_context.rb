# frozen_string_literal: true

module Bugsage
  module ConsoleContext
    module_function

    def set(exception:, context:)
      @exception = exception
      @context = context || {}
    end

    def load_from_event(event)
      return false unless event

      klass = safe_constantize(event[:exception_class])
      message = event[:exception_message].to_s
      message = event[:root_cause].to_s if message.empty?

      set(
        exception: klass.new(message),
        context: event[:context] || {}
      )
      true
    end

    def clear!
      @exception = nil
      @context = {}
    end

    def binding_for_eval
      exception = @exception
      request_context = @context || {}
      params = request_context["Request parameters"] || request_context["Path parameters"] || {}

      binding
    end

    def available?
      !@exception.nil?
    end

    def safe_constantize(name)
      return StandardError if name.to_s.strip.empty?

      Object.const_get(name)
    rescue NameError
      StandardError
    end
  end
end
