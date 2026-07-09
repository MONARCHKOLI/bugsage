# frozen_string_literal: true

module Bugsage
  module ExceptionSupport
    module_function

    ENV_KEYS = %w[
      action_dispatch.exception
      action_dispatch.original_exception
      action_dispatch.debug_exception
      rack.exception
    ].freeze

    def extract(env, exception = nil)
      candidate = exception || env_values(env).find { |value| value } || request_exception(env)
      unwrap(candidate)
    end

    def env_values(env)
      return [] unless env.is_a?(Hash)

      ENV_KEYS.filter_map { |key| env[key] }
    end

    def unwrap(object)
      current = object

      5.times do
        break if current.nil?
        return current if current.is_a?(Exception)

        current = next_exception_candidate(current)
      end

      current.is_a?(Exception) ? current : nil
    end

    def next_exception_candidate(object)
      if object.respond_to?(:unwrapped_exception)
        return object.unwrapped_exception
      end

      if object.respond_to?(:exception)
        candidate = object.exception
        return candidate unless candidate.equal?(object)
      end

      nil
    end

    def wrapper?(object)
      object.class.name&.end_with?("ExceptionWrapper")
    end

    def routing_error?(exception)
      matches_class?(exception, "ActionController::RoutingError") ||
        message_matches?(exception, /No route matches/i)
    end

    def record_not_found?(exception)
      matches_class?(exception, "ActiveRecord::RecordNotFound")
    end

    def matches_class?(exception, class_name)
      exception_ancestor_names(exception).include?(class_name)
    end

    def matches_any_class?(exception, *class_names)
      (exception_ancestor_names(exception) & class_names).any?
    end

    def message_matches?(exception, pattern)
      exception.message.to_s.match?(pattern)
    end

    def exception_class_name(exception)
      exception.class.name.to_s
    end

    # Returns the class *and* its ancestor class names so that subclasses of a
    # known exception (e.g. PG::UniqueViolation < PG::Error, or a wrapped
    # ActiveRecord::StatementInvalid) still match their base rule.
    def exception_ancestor_names(exception)
      exception.class.ancestors.filter_map do |ancestor|
        ancestor.name if ancestor.is_a?(Class)
      end
    end

    def request_exception(env)
      request = env["action_dispatch.request"]
      return unless request
      return request.exception if request.respond_to?(:exception) && request.exception

      nil
    end
  end
end
