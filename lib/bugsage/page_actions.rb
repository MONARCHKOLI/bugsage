# frozen_string_literal: true

require "json"

module Bugsage
  module PageActions
    module_function

    def render_clear_button(label: Bugsage.t("ui.page_actions.clear_session_logs"))
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
            #{CodeContext.escape_html(Bugsage.t("ui.page_actions.open_in_cursor"))}
          </button>
          <button type="button" class="secondary-button bugsage-open-editor" data-editor="vscode" data-url="#{CodeContext.escape_html(editor[:vscode])}">
            #{CodeContext.escape_html(Bugsage.t("ui.page_actions.open_in_vscode"))}
          </button>
          <button type="button" class="secondary-button bugsage-copy-fix">#{CodeContext.escape_html(Bugsage.t("ui.page_actions.copy_fix"))}</button>
          <button type="button" class="secondary-button bugsage-apply-fix">#{CodeContext.escape_html(Bugsage.t("ui.page_actions.apply_fix_to_file"))}</button>
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
      empty_list_html = <<~HTML.strip.gsub("\n", "")
        <div class="empty-list"><p>#{CodeContext.escape_html(Bugsage.t("ui.dashboard.empty_list_title"))}</p><p class="empty-hint">#{CodeContext.escape_html(Bugsage.t("ui.dashboard.empty_list_hint"))}</p></div>
      HTML
      empty_detail_html = <<~HTML.strip.gsub("\n", "")
        <div class="detail-placeholder"><h2>#{CodeContext.escape_html(Bugsage.t("ui.dashboard.empty_detail_title"))}</h2><p>#{CodeContext.escape_html(Bugsage.t("ui.dashboard.empty_detail_body"))}</p></div>
      HTML

      <<~HTML
        <script>
          (function () {
            if (window.__bugsagePageActionsInitialized) return;
            window.__bugsagePageActionsInitialized = true;

            var EMPTY_LIST_HTML = #{JSON.generate(empty_list_html)};
            var EMPTY_DETAIL_HTML = #{JSON.generate(empty_detail_html)};
            var CAUGHT_COUNT_ZERO = #{JSON.generate(Bugsage.t("ui.dashboard.caught_count", count: 0))};
            var AVG_EMPTY = #{JSON.generate(Bugsage.t("ui.dashboard.avg_empty"))};
            var CONFIRM_CLEAR = #{JSON.generate(Bugsage.t("ui.page_actions.confirm_clear"))};
            var COULD_NOT_CLEAR = #{JSON.generate(Bugsage.t("ui.page_actions.could_not_clear"))};
            var QUICK_FIX_TITLE = #{JSON.generate(Bugsage.t("ui.page_actions.quick_fix_title"))};
            var QUICK_FIX_LOCATION = #{JSON.generate(Bugsage.t("ui.page_actions.quick_fix_location"))};
            var QUICK_FIX_SUGGESTION = #{JSON.generate(Bugsage.t("ui.page_actions.quick_fix_suggestion"))};
            var COPIED = #{JSON.generate(Bugsage.t("ui.page_actions.copied"))};
            var COPY_FIX = #{JSON.generate(Bugsage.t("ui.page_actions.copy_fix"))};
            var CONFIRM_APPLY = #{JSON.generate(Bugsage.t("ui.page_actions.confirm_apply"))};
            var APPLYING = #{JSON.generate(Bugsage.t("ui.page_actions.applying"))};
            var COULD_NOT_APPLY = #{JSON.generate(Bugsage.t("ui.page_actions.could_not_apply"))};
            var APPLIED = #{JSON.generate(Bugsage.t("ui.page_actions.applied"))};

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
                bugList.innerHTML = EMPTY_LIST_HTML;
              }

              if (detailPanel) {
                detailPanel.innerHTML = EMPTY_DETAIL_HTML;
              }

              if (statPills[0]) statPills[0].textContent = CAUGHT_COUNT_ZERO;
              if (statPills[1]) statPills[1].textContent = AVG_EMPTY;
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
                if (!window.confirm(CONFIRM_CLEAR)) return;

                clearButton.disabled = true;
                fetch("#{SessionClear::ENDPOINT}", {
                  method: "POST",
                  headers: { "Content-Type": "application/json", "Accept": "application/json" }
                })
                  .then(function (response) { return response.json(); })
                  .then(function () { clearDashboardUi(); })
                  .catch(function (error) {
                    clearButton.disabled = false;
                    window.alert(error.message || COULD_NOT_CLEAR);
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
                  QUICK_FIX_TITLE,
                  QUICK_FIX_LOCATION.replace("%{location}", location),
                  QUICK_FIX_SUGGESTION.replace("%{fix}", fix)
                ].join("\\n");
                clipboardCopy(prompt).then(function () {
                  copyButton.textContent = COPIED;
                  setTimeout(function () { copyButton.textContent = COPY_FIX; }, 1500);
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
                if (!window.confirm(CONFIRM_APPLY)) return;

                var originalText = applyButton.textContent;
                applyButton.disabled = true;
                applyButton.textContent = APPLYING;
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
                      window.alert(result.error || COULD_NOT_APPLY);
                      return;
                    }

                    applyButton.textContent = APPLIED;
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
