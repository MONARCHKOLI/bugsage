# frozen_string_literal: true

require "json"

module Bugsage
  class FixApplicator
    ENDPOINT = "/bugsage/apply-fix"

    def self.handle_request(env)
      return not_found unless Bugsage.configuration.enabled?
      return forbidden unless apply_allowed?

      payload = parse_request_body(env)
      location = payload["location"].to_s
      fix = payload["fix"].to_s.strip
      code_patch = payload["code_patch"]
      code_fix = payload["code_fix"].to_s.strip
      mode = payload["mode"].to_s.strip

      return json_response(error_response("Location is required.")) if location.empty?
      if code_patch.nil? && code_fix.empty? && fix.empty?
        return json_response(error_response("Fix text or AI code patch is required."))
      end

      result = apply(
        location: location,
        fix: fix,
        code_patch: code_patch,
        code_fix: code_fix,
        mode: mode
      )
      json_response(result)
    end

    def self.apply(location:, fix: "", code_patch: nil, code_fix: "", mode: "comment")
      file_path, line_number = CodeContext.extract_location(location)
      return error_response("Could not parse the error location.") unless file_path && line_number
      return error_response("Source file not found: #{file_path}") unless File.exist?(file_path)

      lines = File.readlines(file_path, chomp: true)
      return error_response("Line #{line_number} is out of range.") if line_number < 1 || line_number > lines.length

      if code_patch
        apply_patch!(lines, code_patch, line_number)
      elsif !code_fix.empty? && mode != "comment"
        patch = CodePatch.from_legacy(code_fix, line_number)
        apply_patch!(lines, patch, line_number)
      else
        apply_comment!(lines, line_number, fix)
      end

      File.write(file_path, "#{lines.join("\n")}\n")

      editor = EditorLinks.for_location("#{file_path}:#{line_number}")
      {
        ok: true,
        message: "AI fix applied to #{file_path}:#{line_number}.",
        file_path: editor[:file_path],
        line_number: editor[:line_number],
        editor_links: editor
      }
    rescue Bugsage::Error => e
      error_response(e.message)
    rescue StandardError => e
      error_response("#{e.class}: #{e.message}")
    end

    def self.apply_patch!(lines, patch_data, _error_line)
      patch = case patch_data
              when CodePatch then patch_data
              when Hash then CodePatch.from_hash(patch_data)
              end
      raise Bugsage::Error, "AI code patch is missing." unless patch

      if patch.action == "no_change"
        raise Bugsage::Error, "AI determined no code change is required."
      end

      if patch.duplicates_existing?(lines)
        raise Bugsage::Error, "Suggested code already exists in this file. No changes applied."
      end

      patch.apply!(lines)
    end

    def self.apply_comment!(lines, line_number, fix)
      marker = "# BUGSAGE:"
      comment = "#{marker} #{fix}"
      return if line_number > 1 && lines[line_number - 2].to_s.include?(marker)

      lines.insert(line_number - 1, comment)
    end

    def self.apply_allowed?
      env = Bugsage.configuration.current_environment
      %w[development test].include?(env.to_s)
    end

    def self.error_response(message)
      { ok: false, error: message.to_s }
    end

    def self.parse_request_body(env)
      body = env["rack.input"]
      raw = body.respond_to?(:read) ? body.read : body.to_s
      body.rewind if body.respond_to?(:rewind)

      return {} if raw.to_s.strip.empty?

      JSON.parse(raw)
    rescue JSON::ParserError
      {}
    end

    def self.json_response(payload)
      [200, { "Content-Type" => "application/json" }, [JSON.generate(payload)]]
    end

    def self.not_found
      [404, { "Content-Type" => "text/plain" }, ["Not Found"]]
    end

    def self.forbidden
      [403, { "Content-Type" => "application/json" }, [JSON.generate(error_response("Fix application is only available in development and test."))]]
    end
  end
end
