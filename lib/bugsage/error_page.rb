# frozen_string_literal: true

require "cgi"
require "json"

module Bugsage
  class ErrorPage
    def self.render(suggestion, context = {})
      file_path, line_number = extract_location(suggestion.location)
      code_context = render_code_context(file_path, line_number)

      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <title>BugSage — #{suggestion.issue}</title>
          <style>
            * { box-sizing: border-box; }
            body {
              background: linear-gradient(135deg, #1e1e2e 0%, #2a2a3e 100%);
              color: #cdd6f4;
              font-family: 'SF Mono', Consolas, 'Courier New', monospace;
              padding: 0;
              margin: 0;
              min-height: 100vh;
            }
            .container {
              max-width: 1000px;
              margin: 0 auto;
              padding: 40px 20px;
            }
            h1 {
              color: #f38ba8;
              font-size: 32px;
              margin: 0 0 24px 0;
              display: flex;
              align-items: center;
              gap: 12px;
            }
            .header-info {
              background: rgba(63, 63, 95, 0.5);
              border-left: 4px solid #f38ba8;
              padding: 16px;
              border-radius: 4px;
              margin-bottom: 24px;
            }
            .header-info p {
              margin: 8px 0;
              font-size: 14px;
            }
            .code-section {
              background: #313244;
              border-radius: 8px;
              margin: 24px 0;
              overflow: hidden;
              border: 1px solid #45475a;
            }
            .code-header {
              background: #45475a;
              padding: 12px 16px;
              border-bottom: 1px solid #585869;
              color: #a6e3a1;
              font-size: 12px;
              font-weight: bold;
            }
            .code-block {
              background: #1e1e2e;
              padding: 0;
              max-height: 600px;
              overflow-y: auto;
            }
            .code-line {
              display: flex;
              border-bottom: 1px solid #45475a;
            }
            .code-line:last-child {
              border-bottom: none;
            }
            .code-line-number {
              background: #313244;
              color: #6e7086;
              padding: 8px 16px;
              text-align: right;
              min-width: 60px;
              border-right: 1px solid #45475a;
              user-select: none;
              font-size: 12px;
            }
            .code-line-content {
              flex: 1;
              padding: 8px 16px;
              white-space: pre;
              overflow-x: auto;
              font-size: 13px;
              color: #cdd6f4;
            }
            .code-line.error {
              background: rgba(243, 139, 168, 0.1);
              border-left: 3px solid #f38ba8;
            }
            .code-line.error .code-line-number {
              background: rgba(243, 139, 168, 0.2);
              color: #f38ba8;
              font-weight: bold;
            }
            .section {
              margin-top: 24px;
            }
            .label {
              color: #89b4fa;
              text-transform: uppercase;
              font-size: 11px;
              letter-spacing: 2px;
              margin-bottom: 12px;
              font-weight: bold;
            }
            .value {
              background: #313244;
              padding: 12px 16px;
              border-radius: 6px;
              word-break: break-all;
              white-space: pre-wrap;
              border-left: 3px solid #89b4fa;
            }
            .message-box {
              background: rgba(243, 139, 168, 0.1);
              border-left: 4px solid #f38ba8;
              padding: 16px;
              border-radius: 4px;
              margin-bottom: 24px;
              color: #f5c2e7;
            }
            .fixes {
              list-style: none;
              padding: 0;
              margin: 0;
            }
            .fixes li {
              background: rgba(166, 227, 161, 0.1);
              padding: 12px 16px;
              border-radius: 6px;
              margin-bottom: 8px;
              border-left: 3px solid #a6e3a1;
            }
            .fixes li::before {
              content: "✓ ";
              color: #a6e3a1;
              font-weight: bold;
            }
            .confidence {
              display: inline-block;
              background: #a6e3a1;
              color: #1e1e2e;
              padding: 6px 16px;
              border-radius: 20px;
              font-weight: bold;
              font-size: 13px;
            }
            .row {
              display: grid;
              grid-template-columns: 1fr 1fr;
              gap: 24px;
              margin-bottom: 24px;
            }
            @media (max-width: 768px) {
              .row { grid-template-columns: 1fr; }
            }
          </style>
        </head>
        <body>
          <div class="container">
            <h1>🐛 #{escape_html(suggestion.issue)}</h1>

            <div class="header-info">
              <p><strong>Location:</strong> #{escape_html(suggestion.location)}</p>
            </div>

            #{code_context}

            <div class="message-box">
              <strong>Error Message:</strong><br>
              #{escape_html(suggestion.root_cause)}
            </div>

            #{render_request_context(context)}

            <div class="row">
              <div class="section">
                <div class="label">Suggested Fixes</div>
                <ul class="fixes">
                  #{suggestion.fixes.map { |f| "<li>#{escape_html(f)}</li>" }.join}
                </ul>
              </div>
              <div class="section">
                <div class="label">Confidence Level</div>
                <div style="padding-top: 12px;">
                  <span class="confidence">#{suggestion.confidence}%</span>
                </div>
              </div>
            </div>
          </div>
        </body>
        </html>
      HTML
    end

    def self.render_request_context(context)
      return "" if context.empty?

      rows = context.map do |label, value|
        "<div class=\"section\"><div class=\"label\">#{escape_html(label)}</div>" \
          "<div class=\"value\">#{escape_html(format_value(value))}</div></div>"
      end.join

      "<div class=\"section\"><div class=\"label\">Rails Request Context</div>#{rows}</div>"
    end

    def self.format_value(value)
      case value
      when Hash, Array
        JSON.pretty_generate(value)
      when NilClass
        "n/a"
      else
        value.to_s
      end
    end

    def self.source_excerpt(suggestion)
      return "No source excerpt available" unless suggestion.location

      line = suggestion.location[/:(\d+)/, 1]
      return suggestion.location unless line

      "Line #{line} in #{suggestion.location.split(":").first}"
    end

    def self.source_excerpt(suggestion)
      return "No source excerpt available" unless suggestion.location

      line = suggestion.location[/:(\d+)/, 1]
      return suggestion.location unless line

      "Line #{line} in #{suggestion.location.split(":").first}"
    end

    def self.extract_location(location)
      return [nil, nil] unless location

      match = location.match(/^(.+):(\d+)/)
      return [match[1], match[2].to_i] if match

      [location, nil]
    end

    def self.render_code_context(file_path, line_number)
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

    def self.read_file_lines(file_path)
      return nil unless file_path && File.exist?(file_path)

      File.readlines(file_path)
    rescue StandardError
      nil
    end

    def self.escape_html(value)
      CGI.escapeHTML(value.to_s)
    end
  end
end
