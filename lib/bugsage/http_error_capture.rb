# frozen_string_literal: true

require "json"

module Bugsage
  module HttpErrorCapture
    module_function

    def capture?(status, env)
      return false unless status.to_i >= 400
      return false if bugsage_path?(env)
      return false if ExceptionSupport.extract(env)

      true
    end

    def build_exception(env, status, body)
      body_text = body.to_s.strip
      location = location_for(env)
      message = build_message(status, body_text, location)

      HttpResponseError.new(
        status: status.to_i,
        message: message,
        response_body: body_text.empty? ? nil : body_text,
        location: location
      )
    end

    def location_for(env)
      params = env["action_dispatch.request.path_parameters"]
      return Bugsage.t("common.unknown") unless params.is_a?(Hash)

      controller = params[:controller] || params["controller"]
      action = params[:action] || params["action"]
      return Bugsage.t("common.unknown") if controller.to_s.strip.empty?

      "#{format_controller_name(controller)}Controller##{action}"
    end

    def format_controller_name(controller)
      controller.to_s.split("/").map do |segment|
        segment.split("_").map(&:capitalize).join
      end.join("::")
    end

    def build_message(status, body, location)
      status_label = http_status_label(status)
      detail = extract_detail(body)
      base = Bugsage.t("http_errors.message.base", status: status, status_label: status_label)
      unknown = Bugsage.t("common.unknown")
      base += Bugsage.t("http_errors.message.at_location", location: location) unless location == unknown
      detail.empty? ? base : "#{base}#{Bugsage.t("http_errors.message.with_detail", detail: detail)}"
    end

    def extract_detail(body)
      return "" if body.to_s.strip.empty?

      payload = JSON.parse(body)
      return body.strip unless payload.is_a?(Hash)

      detail = payload["error"] || payload["message"] || payload["errors"]
      case detail
      when String
        detail.strip
      when Hash
        detail.map { |key, value| "#{key}: #{value}" }.join(", ")
      when Array
        detail.join(", ")
      else
        body.strip
      end
    rescue JSON::ParserError
      body.strip
    end

    def bugsage_path?(env)
      path = env["PATH_INFO"].to_s
      path.start_with?("/bugsage")
    end

    def http_status_label(status)
      if defined?(Rack::Utils)
        Rack::Utils::HTTP_STATUS_CODES[status.to_i] || Bugsage.t("http_errors.status_label_fallback", status: status)
      else
        Bugsage.t("http_errors.status_label_fallback", status: status)
      end
    end

    def fixes_for_status(status)
      fixes = Bugsage.t("http_errors.fixes.#{status.to_i}", default: nil)
      fixes = Bugsage.t("http_errors.fixes.default", default: nil) if fixes.nil?
      Array(fixes)
    end

    def confidence_for_status(status)
      case status.to_i
      when 400, 401, 422 then 86
      when 403, 404 then 84
      else 80
      end
    end
  end
end
