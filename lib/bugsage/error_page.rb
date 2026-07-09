require "cgi"
require "json"

module Bugsage
  class ErrorPage
    def self.render(suggestion, context = {})
      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <title>BugSage — #{suggestion.issue}</title>
          <style>
            body {
              background: #1e1e2e;
              color: #cdd6f4;
              font-family: 'SF Mono', Consolas, monospace;
              padding: 40px;
              max-width: 800px;
              margin: 0 auto;
            }
            h1 {
              color: #f38ba8;
              font-size: 24px;
              border-bottom: 2px solid #45475a;
              padding-bottom: 12px;
            }
            .section {
              margin-top: 24px;
            }
            .label {
              color: #89b4fa;
              text-transform: uppercase;
              font-size: 12px;
              letter-spacing: 1px;
              margin-bottom: 6px;
            }
            .value {
              background: #313244;
              padding: 12px 16px;
              border-radius: 6px;
              word-break: break-all;
              white-space: pre-wrap;
            }
            .fixes { list-style: none; padding: 0; }
            .fixes li {
              background: #313244;
              padding: 10px 16px;
              border-radius: 6px;
              margin-bottom: 8px;
            }
            .fixes li::before { content: "✓ "; color: #a6e3a1; }
            .confidence {
              display: inline-block;
              background: #a6e3a1;
              color: #1e1e2e;
              padding: 4px 12px;
              border-radius: 12px;
              font-weight: bold;
            }
          </style>
        </head>
        <body>
          <h1>🐛 BugSage caught: #{suggestion.issue}</h1>

          <div class="section">
            <div class="label">Exception</div>
            <div class="value">#{escape_html(suggestion.issue)}</div>
          </div>

          <div class="section">
            <div class="label">Location</div>
            <div class="value">#{escape_html(suggestion.location)}</div>
          </div>

          <div class="section">
            <div class="label">Message</div>
            <div class="value">#{escape_html(suggestion.root_cause)}</div>
          </div>

          <div class="section">
            <div class="label">Source</div>
            <div class="value">#{escape_html(source_excerpt(suggestion))}</div>
          </div>

          #{render_request_context(context)}

          <div class="section">
            <div class="label">Suggested Fixes</div>
            <ul class="fixes">
              #{suggestion.fixes.map { |f| "<li>#{escape_html(f)}</li>" }.join}
            </ul>
          </div>

          <div class="section">
            <div class="label">Confidence</div>
            <span class="confidence">#{suggestion.confidence}%</span>
          </div>
        </body>
        </html>
      HTML
    end

    def self.render_request_context(context)
      return "" if context.empty?

      rows = context.map do |label, value|
        "<div class=\"section\"><div class=\"label\">#{escape_html(label)}</div><div class=\"value\">#{escape_html(format_value(value))}</div></div>"
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

    def self.escape_html(value)
      CGI.escapeHTML(value.to_s)
    end
  end
end