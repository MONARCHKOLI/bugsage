# frozen_string_literal: true

require "json"

module Bugsage
  class FixApplicator
    extend JsonEndpoint

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

      return json_response(error_response(Bugsage.t("errors.location_required"))) if location.empty?
      if code_patch.nil? && code_fix.empty? && fix.empty?
        return json_response(error_response(Bugsage.t("errors.fix_text_or_patch_required")))
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
      return error_response(Bugsage.t("errors.could_not_parse_location")) unless file_path && line_number
      unless File.exist?(file_path)
        return error_response(Bugsage.t("errors.source_file_not_found",
                                        file_path: file_path))
      end

      lines = File.readlines(file_path, chomp: true)
      if line_number < 1 || line_number > lines.length
        return error_response(Bugsage.t("errors.line_out_of_range",
                                        line_number: line_number))
      end

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
        message: Bugsage.t("errors.fix_applied", file_path: file_path, line_number: line_number),
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
      raise Bugsage::Error, Bugsage.t("errors.ai_code_patch_missing") unless patch

      raise Bugsage::Error, Bugsage.t("errors.no_code_change_required") if patch.action == "no_change"

      raise Bugsage::Error, Bugsage.t("errors.suggested_code_already_exists") if patch.duplicates_existing?(lines)

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

    def self.forbidden
      json_response(error_response(Bugsage.t("errors.fix_only_in_dev_test")), status: 403)
    end
  end
end
