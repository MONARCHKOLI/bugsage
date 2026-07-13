# frozen_string_literal: true

require "cgi"

module Bugsage
  module CodeContext
    module_function

    def extract_location(location)
      return [nil, nil] unless location

      match = location.match(/^(.+):(\d+)/)
      return [match[1], match[2].to_i] if match

      [location, nil]
    end

    def render_code_context(file_path, line_number)
      return "" unless file_path && line_number

      lines = read_file_lines(file_path)
      return "" unless lines

      context_range = 5
      start_line = [line_number - context_range, 1].max
      end_line = [line_number + context_range, lines.length].min

      code_html = ""
      (start_line..end_line).each do |num|
        is_error_line = num == line_number
        line_content = lines[num - 1] || ""
        error_class = is_error_line ? " error" : ""

        code_html += "<div class=\"code-line#{error_class}\">"
        code_html += "<div class=\"code-line-number\">#{num}</div>"
        code_html += "<div class=\"code-line-content\">#{escape_html(line_content)}</div>"
        code_html += "</div>"
      end

      <<~HTML
        <div class="code-section">
          <div class="code-header">#{escape_html(file_path)}</div>
          <div class="code-block">
            #{code_html}
          </div>
        </div>
      HTML
    end

    def numbered_source(file_path, line_number, context_range: 20)
      lines = read_file_lines(file_path)
      return nil unless lines

      start_line = [line_number - context_range, 1].max
      end_line = [line_number + context_range, lines.length].min
      source = (start_line..end_line).map do |num|
        marker = num == line_number ? ">>" : "  "
        "#{marker} #{num.to_s.rjust(4)} | #{lines[num - 1]}"
      end.join("\n")

      {
        start_line: start_line,
        end_line: end_line,
        error_line: line_number,
        source: source
      }
    end

    def read_file_lines(file_path)
      return nil unless file_path && File.exist?(file_path)

      File.readlines(file_path, chomp: true)
    rescue StandardError
      nil
    end

    def escape_html(value)
      CGI.escapeHTML(value.to_s)
    end
  end
end
