# frozen_string_literal: true

require "json"

module Bugsage
  class Dashboard
    def self.render(suggestions)
      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <title>BugSage Dashboard</title>
          <style>
            #{shared_styles}
          </style>
        </head>
        <body>
          <div class="dashboard">
            <aside class="sidebar">
              <header class="sidebar-header">
                <h1>🐛 BugSage</h1>
                <p class="sidebar-subtitle">Session errors</p>
                <div class="sidebar-stats">
                  <span class="stat-pill">#{suggestions.size} caught</span>
                  <span class="stat-pill">#{suggestions.empty? ? "—" : "#{average_confidence(suggestions)}% avg"}</span>
                </div>
                #{PageActions.render_clear_button unless suggestions.empty?}
              </header>

              <div class="bug-list">
                #{suggestions.empty? ? render_empty_list : suggestions.map.with_index { |event, index| render_list_item(event, index) }.join}
              </div>
            </aside>

            <main class="detail-panel">
              #{suggestions.empty? ? render_empty_detail : suggestions.map.with_index { |event, index| render_detail(event, index) }.join}
              #{render_detail_script unless suggestions.empty?}
              #{InlineConsole.render_script if Bugsage.configuration.show_inline_console? && !suggestions.empty?}
              #{AiPanel.render_script if Bugsage.configuration.ai_configured? && !suggestions.empty?}
              #{PageActions.render_script unless suggestions.empty?}
            </main>
          </div>
        </body>
        </html>
      HTML
    end

    def self.render_empty_list
      <<~HTML
        <div class="empty-list">
          <p>No issues yet</p>
          <p class="empty-hint">Trigger an exception and it will appear here.</p>
        </div>
      HTML
    end

    def self.render_empty_detail
      <<~HTML
        <div class="detail-placeholder">
          <h2>No errors captured</h2>
          <p>When BugSage catches an exception, select it from the list on the left to inspect the failing code, message, and suggested fixes.</p>
        </div>
      HTML
    end

    def self.render_list_item(event, index)
      active_class = index.zero? ? " active" : ""

      <<~HTML
        <button type="button" class="bug-item#{active_class}" data-bug-id="bug-#{index}" aria-controls="bug-#{index}">
          <div class="bug-item-heading">
            <span class="issue">#{CodeContext.escape_html(event[:issue])}</span>
            <span class="confidence">#{event[:confidence]}%</span>
          </div>
          <div class="location">#{CodeContext.escape_html(short_location(event[:location]))}</div>
          <p class="cause-preview">#{CodeContext.escape_html(truncate(event[:root_cause], 80))}</p>
          <span class="meta">#{CodeContext.escape_html(event[:timestamp])}</span>
        </button>
      HTML
    end

    def self.render_detail(event, index)
      file_path, line_number = CodeContext.extract_location(event[:location])
      code_context = CodeContext.render_code_context(file_path, line_number)
      context = event[:context] || {}
      fixes = event[:fixes] || []
      active_class = index.zero? ? " active" : ""
      hidden_attr = index.zero? ? "" : ' hidden'

      <<~HTML
        <section id="bug-#{index}" class="bug-detail#{active_class}"#{hidden_attr}>
          <header class="detail-header">
            <h2>#{CodeContext.escape_html(event[:issue])}</h2>
            <span class="confidence-badge" id="bugsage-confidence-bug-#{index}">#{event[:confidence]}% confidence</span>
            #{render_source_badge(event)}
          </header>

          <div class="detail-meta">
            <span><strong>Location:</strong> #{CodeContext.escape_html(event[:location])}</span>
            <span><strong>Time:</strong> #{CodeContext.escape_html(event[:timestamp])}</span>
          </div>

          #{code_context}

          <div class="message-box">
            <strong>Error Message:</strong>
            <p>#{CodeContext.escape_html(event[:root_cause])}</p>
          </div>

          #{InlineConsole.render_panel(bug_index: index, include_script: false)}

          #{AiPanel.render_panel(bug_index: index, include_script: false, suggestion: suggestion_from_event(event))}

          <div class="detail-grid">
            <div class="detail-section">
              <div class="label">Suggested fixes</div>
              <ul class="fixes" id="bugsage-fixes-bug-#{index}">
                #{fixes.map.with_index { |fix, fix_index| "<li#{fix_index.zero? ? ' class=\"selected\"' : ''}>#{CodeContext.escape_html(fix)}</li>" }.join}
              </ul>
              #{PageActions.render_fix_actions(location: event[:location], suffix: "-bug-#{index}", hidden: false)}
            </div>

            <div class="detail-section">
              <div class="label">Analysis</div>
              <p class="confidence-detail">#{analysis_summary(event)}</p>
            </div>
          </div>

          #{render_request_context(context)}
        </section>
      HTML
    end

    def self.render_detail_script
      <<~HTML
        <script>
          (function () {
            var items = document.querySelectorAll(".bug-item");
            var panels = document.querySelectorAll(".bug-detail");

            function showBug(id) {
              items.forEach(function (item) {
                item.classList.toggle("active", item.dataset.bugId === id);
              });

              panels.forEach(function (panel) {
                var isActive = panel.id === id;
                panel.classList.toggle("active", isActive);
                panel.hidden = !isActive;
              });
            }

            items.forEach(function (item) {
              item.addEventListener("click", function () {
                showBug(item.dataset.bugId);
              });
            });
          })();
        </script>
      HTML
    end

    def self.render_request_context(context)
      return "" if context.nil? || context.empty?

      rows = context.map do |label, value|
        "<div class=\"context-row\">" \
          "<div class=\"context-label\">#{CodeContext.escape_html(label)}</div>" \
          "<div class=\"context-value\">#{CodeContext.escape_html(format_value(value))}</div>" \
          "</div>"
      end.join

      <<~HTML
        <div class="detail-section">
          <div class="label">Rails request context</div>
          <div class="context-panel">#{rows}</div>
        </div>
      HTML
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

    def self.analysis_summary(event)
      confidence = event[:confidence]
      source = event[:source].to_s
      ai_error = event[:ai_error].to_s.strip

      return "AI analysis was enabled but failed: #{ai_error}" unless ai_error.empty?

      case source
      when "hybrid", "ai"
        "#{confidence}% confidence after combining BugSage rules with AI analysis."
      else
        "#{confidence}% match for this exception type based on BugSage rules."
      end
    end

    def self.suggestion_from_event(event)
      Suggestion.new(
        issue: event[:issue],
        location: event[:location],
        root_cause: event[:root_cause],
        fixes: event[:fixes] || [],
        confidence: event[:confidence],
        source: event[:source] || :rules,
        ai_notes: event[:ai_notes],
        code_patch: event[:code_patch]
      )
    end

    def self.render_source_badge(event)
      return "" unless %w[hybrid ai].include?(event[:source].to_s)

      '<span class="source-badge">AI-enhanced</span>'
    end

    def self.render_ai_notes(event)
      notes = event[:ai_notes].to_s.strip
      return "" if notes.empty?

      <<~HTML
        <div class="detail-section">
          <div class="label">AI notes</div>
          <div class="ai-notes">#{CodeContext.escape_html(notes)}</div>
        </div>
      HTML
    end

    def self.render_ai_error(event)
      error = event[:ai_error].to_s.strip
      return "" if error.empty?

      <<~HTML
        <div class="detail-section">
          <div class="label">AI status</div>
          <div class="ai-error">AI analysis was enabled but could not run: #{CodeContext.escape_html(error)}</div>
        </div>
      HTML
    end

    def self.short_location(location)
      return "unknown" unless location

      file_path, line_number = CodeContext.extract_location(location)
      return location unless file_path

      file_name = File.basename(file_path)
      line_number ? "#{file_name}:#{line_number}" : file_name
    end

    def self.truncate(text, length)
      value = text.to_s
      return value if value.length <= length

      "#{value[0, length - 3]}..."
    end

    def self.average_confidence(suggestions)
      return 0 if suggestions.empty?

      total = suggestions.sum { |event| event[:confidence].to_i }
      (total.to_f / suggestions.size).round
    end

    def self.shared_styles
      <<~CSS
        * { box-sizing: border-box; }
        body {
          background: #1e1e2e;
          color: #cdd6f4;
          font-family: 'SF Mono', Consolas, 'Courier New', monospace;
          margin: 0;
          min-height: 100vh;
        }
        .dashboard {
          display: grid;
          grid-template-columns: 340px 1fr;
          min-height: 100vh;
        }
        .sidebar {
          background: #181825;
          border-right: 1px solid #45475a;
          display: flex;
          flex-direction: column;
          min-height: 100vh;
        }
        .sidebar-header {
          padding: 24px 20px;
          border-bottom: 1px solid #45475a;
        }
        .sidebar-header h1 {
          color: #f38ba8;
          font-size: 22px;
          margin: 0 0 4px 0;
        }
        .sidebar-subtitle {
          color: #a6adc8;
          margin: 0 0 16px 0;
          font-size: 13px;
        }
        .sidebar-stats {
          display: flex;
          flex-wrap: wrap;
          gap: 8px;
        }
        .stat-pill {
          background: rgba(137, 180, 250, 0.15);
          color: #89b4fa;
          padding: 4px 10px;
          border-radius: 999px;
          font-size: 11px;
          font-weight: bold;
        }
        .bug-list {
          flex: 1;
          overflow-y: auto;
          padding: 12px;
        }
        .bug-item {
          width: 100%;
          text-align: left;
          background: #313244;
          border: 1px solid #45475a;
          border-radius: 8px;
          padding: 14px 16px;
          margin-bottom: 10px;
          cursor: pointer;
          color: inherit;
          font: inherit;
          transition: border-color 0.15s ease, background 0.15s ease;
        }
        .bug-item:hover {
          border-color: #89b4fa;
          background: #3b3d52;
        }
        .bug-item.active {
          border-color: #f38ba8;
          background: rgba(243, 139, 168, 0.12);
          box-shadow: inset 3px 0 0 #f38ba8;
        }
        .bug-item-heading {
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 8px;
          margin-bottom: 6px;
        }
        .issue {
          color: #f38ba8;
          font-size: 14px;
          font-weight: bold;
        }
        .confidence {
          background: #a6e3a1;
          color: #1e1e2e;
          padding: 2px 8px;
          border-radius: 999px;
          font-size: 11px;
          font-weight: bold;
          white-space: nowrap;
        }
        .location {
          color: #89b4fa;
          font-size: 12px;
          word-break: break-all;
          margin-bottom: 6px;
        }
        .cause-preview {
          margin: 0 0 8px 0;
          color: #cdd6f4;
          font-size: 12px;
          line-height: 1.4;
        }
        .meta {
          color: #6c7086;
          font-size: 11px;
        }
        .empty-list {
          padding: 20px 12px;
          color: #a6adc8;
          text-align: center;
        }
        .empty-hint {
          margin-top: 8px;
          color: #6c7086;
          font-size: 12px;
        }
        .detail-panel {
          background: linear-gradient(135deg, #1e1e2e 0%, #2a2a3e 100%);
          overflow-y: auto;
          padding: 32px;
          min-height: 100vh;
        }
        .detail-placeholder {
          max-width: 560px;
          margin: 80px auto;
          text-align: center;
          color: #a6adc8;
        }
        .detail-placeholder h2 {
          color: #f38ba8;
          margin-bottom: 12px;
        }
        .bug-detail[hidden] { display: none; }
        .sidebar-header .bugsage-clear-logs {
          margin-top: 12px;
          width: 100%;
        }
        .detail-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 16px;
          margin-bottom: 16px;
        }
        .detail-header h2 {
          color: #f38ba8;
          font-size: 28px;
          margin: 0;
        }
        .confidence-badge {
          background: #a6e3a1;
          color: #1e1e2e;
          padding: 6px 14px;
          border-radius: 999px;
          font-size: 12px;
          font-weight: bold;
          white-space: nowrap;
        }
        .source-badge {
          background: rgba(137, 180, 250, 0.2);
          color: #89b4fa;
          padding: 6px 14px;
          border-radius: 999px;
          font-size: 12px;
          font-weight: bold;
          white-space: nowrap;
        }
        .ai-notes {
          background: rgba(137, 180, 250, 0.1);
          border-left: 4px solid #89b4fa;
          padding: 16px;
          border-radius: 4px;
          margin-bottom: 20px;
          white-space: pre-wrap;
        }
        .ai-error {
          background: rgba(250, 179, 135, 0.1);
          border-left: 4px solid #fab387;
          padding: 16px;
          border-radius: 4px;
          margin-bottom: 20px;
          color: #f9e2af;
          white-space: pre-wrap;
        }
        .detail-meta {
          display: flex;
          flex-wrap: wrap;
          gap: 16px 24px;
          color: #a6adc8;
          font-size: 13px;
          margin-bottom: 20px;
        }
        .message-box {
          background: rgba(243, 139, 168, 0.1);
          border-left: 4px solid #f38ba8;
          padding: 16px;
          border-radius: 4px;
          margin-bottom: 20px;
          color: #f5c2e7;
        }
        .message-box strong {
          display: block;
          margin-bottom: 8px;
        }
        .message-box p { margin: 0; }
        .inline-console .label {
          color: #89b4fa;
          text-transform: uppercase;
          font-size: 11px;
          letter-spacing: 2px;
          margin-bottom: 12px;
          font-weight: bold;
        }
        .code-section {
          background: #1e1e2e;
          border-radius: 8px;
          margin: 20px 0;
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
          max-height: 420px;
          overflow-y: auto;
        }
        .code-line {
          display: flex;
          border-bottom: 1px solid #45475a;
        }
        .code-line:last-child { border-bottom: none; }
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
        .detail-grid {
          display: grid;
          grid-template-columns: 2fr 1fr;
          gap: 20px;
          margin: 20px 0;
        }
        .detail-section { margin-top: 4px; }
        .label {
          color: #89b4fa;
          text-transform: uppercase;
          font-size: 11px;
          letter-spacing: 2px;
          margin-bottom: 12px;
          font-weight: bold;
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
        .confidence-detail {
          margin: 0;
          color: #a6adc8;
          line-height: 1.6;
        }
        .context-panel {
          background: #1e1e2e;
          border: 1px solid #45475a;
          border-radius: 6px;
          overflow: hidden;
        }
        .context-row {
          display: grid;
          grid-template-columns: 180px 1fr;
          border-bottom: 1px solid #45475a;
        }
        .context-row:last-child { border-bottom: none; }
        .context-label {
          padding: 12px 16px;
          background: #313244;
          color: #89b4fa;
          font-size: 12px;
          font-weight: bold;
        }
        .context-value {
          padding: 12px 16px;
          white-space: pre-wrap;
          word-break: break-word;
          font-size: 13px;
        }
        #{InlineConsole.styles}
        #{AiPanel.styles}
        #{PageActions.styles}
        .fixes li {
          cursor: pointer;
        }
        .fixes li.selected {
          border-left-color: #89b4fa;
          background: rgba(137, 180, 250, 0.12);
        }
        @media (max-width: 900px) {
          .dashboard { grid-template-columns: 1fr; }
          .sidebar { min-height: auto; border-right: none; border-bottom: 1px solid #45475a; }
          .bug-list { max-height: 280px; }
          .detail-panel { min-height: auto; }
          .detail-grid, .context-row { grid-template-columns: 1fr; }
        }
      CSS
    end
  end
end
