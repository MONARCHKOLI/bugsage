# frozen_string_literal: true

module Bugsage
  module PageActions
    module_function

    def render_clear_button(label: "Clear session logs")
      <<~HTML
        <button type="button" class="bugsage-clear-logs secondary-button">#{CodeContext.escape_html(label)}</button>
      HTML
    end

    def render_fix_actions(location:, suffix: "", hidden: true)
      editor = EditorLinks.for_location(location)
      return "" if editor.empty?

      hidden_class = hidden ? " hidden" : ""
      location_attr = CodeContext.escape_html(location)

      <<~HTML
        <div class="fix-actions#{hidden_class}" id="bugsage-fix-actions#{suffix}" data-location="#{location_attr}">
          <button type="button" class="secondary-button bugsage-open-editor" data-editor="cursor" data-url="#{CodeContext.escape_html(editor[:cursor])}">
            Open in Cursor
          </button>
          <button type="button" class="secondary-button bugsage-open-editor" data-editor="vscode" data-url="#{CodeContext.escape_html(editor[:vscode])}">
            Open in VS Code
          </button>
          <button type="button" class="secondary-button bugsage-copy-fix">Copy Fix</button>
          <button type="button" class="secondary-button bugsage-apply-fix">Apply Fix to File</button>
        </div>
      HTML
    end

    def styles
      <<~CSS
        .page-actions {
          display: flex;
          justify-content: flex-end;
          gap: 8px;
          margin-bottom: 16px;
        }
        .fix-actions {
          display: flex;
          flex-wrap: wrap;
          gap: 8px;
          margin-top: 12px;
        }
        .fix-actions.hidden {
          display: none;
        }
        .secondary-button {
          background: #45475a;
          color: #cdd6f4;
          border: 1px solid #585869;
          border-radius: 6px;
          padding: 8px 12px;
          font-family: inherit;
          font-size: 12px;
          font-weight: bold;
          cursor: pointer;
        }
        .secondary-button:hover {
          border-color: #89b4fa;
          color: #89b4fa;
        }
        .bugsage-clear-logs {
          background: rgba(243, 139, 168, 0.15);
          border-color: #f38ba8;
          color: #f5c2e7;
        }
      CSS
    end

    def render_script
      <<~HTML
        <script>
          (function () {
            if (window.__bugsagePageActionsInitialized) return;
            window.__bugsagePageActionsInitialized = true;

            function selectedFixText(actions) {
              var panel = actions.closest(".bug-detail, .container");
              if (!panel) return "";

              var activeFix = panel.querySelector(".fixes li.selected, .fixes li");
              return activeFix ? activeFix.textContent.trim() : "";
            }

            function clipboardCopy(text) {
              if (navigator.clipboard && navigator.clipboard.writeText) {
                return navigator.clipboard.writeText(text);
              }

              var area = document.createElement("textarea");
              area.value = text;
              document.body.appendChild(area);
              area.select();
              document.execCommand("copy");
              document.body.removeChild(area);
              return Promise.resolve();
            }

            function clearDashboardUi() {
              var bugList = document.querySelector(".bug-list");
              var detailPanel = document.querySelector(".detail-panel");
              var clearButton = document.querySelector(".bugsage-clear-logs");
              var statPills = document.querySelectorAll(".sidebar-stats .stat-pill");

              if (bugList) {
                bugList.innerHTML = '<div class="empty-list"><p>No issues yet</p><p class="empty-hint">Trigger an exception and it will appear here.</p></div>';
              }

              if (detailPanel) {
                detailPanel.innerHTML = '<div class="detail-placeholder"><h2>No errors captured</h2><p>When BugSage catches an exception, select it from the list on the left to inspect the failing code, message, and suggested fixes.</p></div>';
              }

              if (statPills[0]) statPills[0].textContent = "0 caught";
              if (statPills[1]) statPills[1].textContent = "—";
              if (clearButton) clearButton.hidden = true;
            }

            function openEditorUrl(url) {
              var link = document.createElement("a");
              link.href = url;
              link.rel = "noopener";
              link.style.display = "none";
              document.body.appendChild(link);
              link.click();
              document.body.removeChild(link);
            }

            document.addEventListener("click", function (event) {
              var clearButton = event.target.closest(".bugsage-clear-logs");
              if (clearButton) {
                event.preventDefault();
                if (!window.confirm("Clear all BugSage session logs?")) return;

                clearButton.disabled = true;
                fetch("#{SessionClear::ENDPOINT}", {
                  method: "POST",
                  headers: { "Content-Type": "application/json", "Accept": "application/json" }
                })
                  .then(function (response) { return response.json(); })
                  .then(function () { clearDashboardUi(); })
                  .catch(function (error) {
                    clearButton.disabled = false;
                    window.alert(error.message || "Could not clear session logs.");
                  });
                return;
              }

              var openButton = event.target.closest(".bugsage-open-editor");
              if (openButton) {
                event.preventDefault();
                var url = openButton.dataset.url;
                if (url) openEditorUrl(url);
                return;
              }

              var copyButton = event.target.closest(".bugsage-copy-fix");
              if (copyButton) {
                var actions = copyButton.closest(".fix-actions");
                var fix = selectedFixText(actions);
                var location = actions.dataset.location || "";
                var prompt = [
                  "BugSage quick fix",
                  "Location: " + location,
                  "Suggestion: " + fix
                ].join("\\n");
                clipboardCopy(prompt).then(function () {
                  copyButton.textContent = "Copied!";
                  setTimeout(function () { copyButton.textContent = "Copy Fix"; }, 1500);
                });
                return;
              }

              var applyButton = event.target.closest(".bugsage-apply-fix");
              if (applyButton) {
                event.preventDefault();
                var actionBar = applyButton.closest(".fix-actions");
                var fixText = selectedFixText(actionBar);
                var fixLocation = actionBar.dataset.location || "";
                if (!fixText) return;
                if (!window.confirm("Apply this fix to the source file in development?")) return;

                var originalText = applyButton.textContent;
                applyButton.disabled = true;
                applyButton.textContent = "Applying...";
                fetch("#{FixApplicator::ENDPOINT}", {
                  method: "POST",
                  headers: { "Content-Type": "application/json" },
                  body: JSON.stringify({ location: fixLocation, fix: fixText })
                })
                  .then(function (response) { return response.json(); })
                  .then(function (result) {
                    applyButton.disabled = false;
                    applyButton.textContent = originalText;
                    if (!result.ok) {
                      window.alert(result.error || "Could not apply fix.");
                      return;
                    }

                    applyButton.textContent = "Applied!";
                    setTimeout(function () { applyButton.textContent = originalText; }, 2000);
                  })
                  .catch(function (error) {
                    applyButton.disabled = false;
                    applyButton.textContent = originalText;
                    window.alert(error.message);
                  });
              }
            });

            document.addEventListener("click", function (event) {
              var fixItem = event.target.closest(".fixes li");
              if (!fixItem) return;

              var panel = fixItem.closest(".bug-detail, .container");
              if (!panel) return;

              panel.querySelectorAll(".fixes li").forEach(function (item) {
                item.classList.toggle("selected", item === fixItem);
              });
            });
          })();
        </script>
      HTML
    end
  end
end
