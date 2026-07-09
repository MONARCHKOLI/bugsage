# frozen_string_literal: true

module Bugsage
  class Dashboard
    def self.render(suggestions)
      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <title>BugSage Dashboard</title>
          <meta http-equiv="refresh" content="5">
          <style>
            body {
              background: #1e1e2e;
              color: #cdd6f4;
              font-family: 'SF Mono', Consolas, monospace;
              padding: 40px;
              max-width: 900px;
              margin: 0 auto;
            }
            h1 { color: #f38ba8; }
            .count { color: #89b4fa; margin-bottom: 24px; }
            .card {
              background: #313244;
              border-radius: 8px;
              padding: 16px 20px;
              margin-bottom: 16px;
              border-left: 4px solid #f38ba8;
            }
            .issue { color: #f38ba8; font-weight: bold; font-size: 16px; }
            .location { color: #89b4fa; font-size: 13px; margin: 6px 0; word-break: break-all; }
            .cause { margin: 6px 0; }
            .meta { color: #6c7086; font-size: 12px; margin-top: 8px; }
            .confidence {
              display: inline-block;
              background: #a6e3a1;
              color: #1e1e2e;
              padding: 2px 10px;
              border-radius: 10px;
              font-size: 12px;
              font-weight: bold;
              margin-top: 6px;
            }
            .empty { color: #6c7086; }
          </style>
        </head>
        <body>
          <h1>🐛 BugSage Dashboard</h1>
          <div class="count">#{suggestions.size} issue(s) this session</div>
          #{suggestions.empty? ? '<p class="empty">No issues caught yet. Go break something.</p>' : suggestions.map { |s| render_card(s) }.join}
        </body>
        </html>
      HTML
    end

    def self.render_card(suggestion)
      <<~HTML
        <div class="card">
          <div class="issue">#{suggestion[:issue]}</div>
          <div class="location">#{suggestion[:location]}</div>
          <div class="cause">#{suggestion[:root_cause]}</div>
          <div class="meta">#{suggestion[:timestamp]} · #{format_context(suggestion[:context])}</div>
          <span class="confidence">#{suggestion[:confidence]}%</span>
        </div>
      HTML
    end

    def self.format_context(context)
      return "no context" if context.nil? || context.empty?

      context.map { |key, value| "#{key}: #{value}" }.join(" · ")
    end
  end
end
