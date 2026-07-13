# frozen_string_literal: true

module Bugsage
  class CodePatch
    ACTIONS = %w[replace_lines delete_lines insert_before no_change].freeze

    attr_reader :action, :start_line, :end_line, :replacement

    def initialize(action:, start_line:, end_line: nil, replacement: "")
      @action = normalize_action(action)
      @start_line = start_line.to_i
      @end_line = (end_line || start_line).to_i
      @replacement = replacement.to_s
    end

    def self.from_ai(payload, error_line:)
      patch = payload["code_patch"]
      return from_legacy(payload["code_fix"], error_line) if patch.nil? || patch.empty?

      new(
        action: patch["action"],
        start_line: patch["start_line"] || error_line,
        end_line: patch["end_line"] || patch["start_line"] || error_line,
        replacement: patch["replacement"]
      )
    end

    def self.from_legacy(code_fix, error_line)
      text = code_fix.to_s.strip
      return nil if text.empty?

      new(action: "replace_lines", start_line: error_line, end_line: error_line, replacement: text)
    end

    def self.preview_for(patch)
      return nil if patch.nil?

      instance = patch.is_a?(self) ? patch : from_hash(patch)
      instance&.preview
    end

    def self.from_hash(hash)
      return nil if hash.nil? || hash.empty?

      new(
        action: hash[:action] || hash["action"],
        start_line: hash[:start_line] || hash["start_line"],
        end_line: hash[:end_line] || hash["end_line"],
        replacement: hash[:replacement] || hash["replacement"]
      )
    end

    def apply!(lines)
      validate_range!(lines)

      case action
      when "no_change"
        nil
      when "delete_lines"
        delete_lines!(lines)
      when "insert_before"
        insert_before!(lines)
      else
        replace_lines!(lines)
      end
    end

    def preview
      case action
      when "no_change"
        "No code change required."
      when "delete_lines"
        if start_line == end_line
          "- remove line #{start_line}"
        else
          "- remove lines #{start_line}-#{end_line}"
        end
      when "insert_before"
        "+ insert before line #{start_line}:\n#{replacement}"
      else
        if start_line == end_line
          "replace line #{start_line} with:\n#{replacement}"
        else
          "replace lines #{start_line}-#{end_line} with:\n#{replacement}"
        end
      end
    end

    def duplicates_existing?(lines)
      return false if %w[delete_lines no_change].include?(action)
      return true if replacement.strip.empty?

      normalized = normalize_line(replacement)
      lines.any? { |line| normalize_line(line) == normalized }
    end

    def to_h
      {
        action: action,
        start_line: start_line,
        end_line: end_line,
        replacement: replacement
      }
    end

    private

    def normalize_action(value)
      action = value.to_s.strip
      ACTIONS.include?(action) ? action : "replace_lines"
    end

    def validate_range!(lines)
      raise Bugsage::Error, "Invalid patch line range." if start_line < 1 || end_line < start_line
      raise Bugsage::Error, "Patch ends after file end." if end_line > lines.length
    end

    def replace_lines!(lines)
      indent = lines[start_line - 1].to_s[/\A(\s*)/, 1] || ""
      delete_lines!(lines)
      return if replacement.strip.empty?

      lines.insert(start_line - 1, *indented_replacement_lines(indent))
    end

    def insert_before!(lines)
      indent = lines[start_line - 1].to_s[/\A(\s*)/, 1] || ""
      lines.insert(start_line - 1, *indented_replacement_lines(indent))
    end

    def delete_lines!(lines)
      lines.slice!(start_line - 1, end_line - start_line + 1)
    end

    def replacement_lines
      replacement.lines(chomp: true)
    end

    def indented_replacement_lines(indent)
      replacement_lines.map { |line| line.empty? ? line : "#{indent}#{line.lstrip}" }
    end

    def normalize_line(line)
      line.to_s.strip.gsub(/\s+/, " ")
    end
  end
end
