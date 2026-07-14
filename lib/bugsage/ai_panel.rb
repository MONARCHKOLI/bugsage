# frozen_string_literal: true

require "json"

module Bugsage
  class AiPanel
    extend JsonEndpoint

    ENDPOINT = "/bugsage/ai-suggest"

    def self.handle_request(env)
      return not_found unless Bugsage.configuration.ai_configured?

      payload = parse_request_body(env)
      context = load_context(payload)
      return json_response(error_response(Bugsage.t("errors.ai_context_not_available"))) unless context

      suggestion, ai_error = AiAnalyzer.enhance(
        context[:suggestion],
        context[:exception],
        context[:context]
      )

      persist_enhancement!(suggestion, ai_error, payload["index"])
      json_response(serialize(suggestion, ai_error))
    end

    def self.load_context(payload)
      if payload.key?("index")
        event = Store.all[payload["index"].to_i]
        return nil unless AiContext.load_from_event(event)

      end
      AiContext.current
    end

    def self.persist_enhancement!(suggestion, ai_error, index)
      if index
        Store.update_at(index.to_i, suggestion, ai_error: ai_error)
      elsif Store.all.any?
        Store.update_at(0, suggestion, ai_error: ai_error)
      end
    end

    def self.serialize(suggestion, ai_error)
      return error_response(ai_error) if ai_error

      {
        ok: true,
        root_cause: suggestion.root_cause,
        fixes: suggestion.fixes,
        confidence: suggestion.confidence,
        ai_notes: suggestion.ai_notes,
        source: suggestion.source.to_s,
        ai_enhanced: suggestion.ai_enhanced?,
        location: suggestion.location,
        editor_links: EditorLinks.for_location(suggestion.location),
        code_patch: suggestion.code_patch,
        code_fix: suggestion.code_fix
      }
    end

    def self.patch_action(code_patch)
      return nil unless code_patch.is_a?(Hash)

      code_patch[:action] || code_patch["action"]
    end

    def self.render_panel(bug_index: nil, include_script: true, suggestion: nil)
      return "" unless Bugsage.configuration.ai_configured?

      suffix = bug_index.nil? ? "" : "-bug-#{bug_index}"
      panel_id = "bugsage-ai-panel#{suffix}"
      fixes_id = "bugsage-fixes#{suffix}"
      notes_id = "bugsage-ai-notes#{suffix}"
      confidence_id = "bugsage-confidence#{suffix}"
      status_id = "bugsage-ai-status#{suffix}"
      index_attr = bug_index.nil? ? "" : %( data-bug-index="#{bug_index}")
      location_data = suggestion&.location ? %( data-location="#{CodeContext.escape_html(suggestion.location)}") : ""
      patch_available = patch_action(suggestion&.code_patch) && patch_action(suggestion&.code_patch) != "no_change"
      code_patch_data = if patch_available
                          %( data-code-patch="#{CodeContext.escape_html(JSON.generate(suggestion.code_patch))}")
                        else
                          ""
                        end
      enhanced = suggestion&.ai_enhanced?

      <<~HTML
        <div id="#{panel_id}" class="section ai-panel"#{index_attr}#{location_data}#{code_patch_data}>
          <div class="ai-panel-header">
            <div class="label">#{CodeContext.escape_html(Bugsage.t("ui.ai_panel.ai_suggestions"))}</div>
            <div class="ai-panel-header-actions">
              <button type="button" class="ai-chat-toggle bugsage-ai-chat-toggle" title="#{CodeContext.escape_html(Bugsage.t("ui.ai_panel.chat_about_error_title"))}" aria-label="#{CodeContext.escape_html(Bugsage.t("ui.ai_panel.chat_about_error_aria"))}">💬</button>
              <label class="ai-toggle">
                <input type="checkbox" class="bugsage-ai-toggle" checked>
                <span>#{CodeContext.escape_html(Bugsage.t("ui.ai_panel.enable_ai"))}</span>
              </label>
            </div>
          </div>
          #{AiChat.render_widget(suffix: suffix, bug_index: bug_index)}
          <p class="ai-panel-help">
            #{CodeContext.escape_html(Bugsage.t("ui.ai_panel.help"))}
          </p>
          <button type="button" class="quick-fix-button bugsage-quick-fix"#{" hidden" if enhanced}>
            #{CodeContext.escape_html(Bugsage.t("ui.ai_panel.quick_fix_suggestion"))}
          </button>
          <div class="ai-apply-row#{" hidden" unless patch_available}">
            <button type="button" class="apply-ai-button bugsage-apply-ai-codebase">
              #{CodeContext.escape_html(Bugsage.t("ui.ai_panel.apply_ai_to_codebase"))}
            </button>
            <label class="editor-preference">
              <span>#{CodeContext.escape_html(Bugsage.t("ui.ai_panel.open_in"))}</span>
              <select class="bugsage-editor-preference">
                <option value="cursor">#{CodeContext.escape_html(Bugsage.t("ui.ai_panel.cursor"))}</option>
                <option value="vscode">#{CodeContext.escape_html(Bugsage.t("ui.ai_panel.vscode"))}</option>
              </select>
            </label>
          </div>
          <pre class="ai-code-preview#{" hidden" unless patch_available}" id="bugsage-code-preview#{suffix}">#{CodeContext.escape_html(suggestion&.code_fix.to_s)}</pre>
          <div id="#{status_id}" class="ai-status" aria-live="polite"></div>
          <div id="#{notes_id}" class="ai-notes#{" hidden" if suggestion&.ai_notes.to_s.strip.empty?}">
            #{CodeContext.escape_html(suggestion&.ai_notes.to_s)}
          </div>
        </div>
        <template id="bugsage-ai-targets#{suffix}" data-fixes-target="##{fixes_id}" data-confidence-target="##{confidence_id}" data-notes-target="##{notes_id}" data-status-target="##{status_id}"></template>
        #{render_script if include_script}
      HTML
    end

    def self.styles
      <<~CSS
        .ai-panel {
          background: #313244;
          border: 1px solid #45475a;
          border-radius: 8px;
          padding: 16px;
          margin-bottom: 20px;
          position: relative;
        }
        .ai-panel-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 12px;
          margin-bottom: 8px;
        }
        .ai-panel-help {
          color: #a6adc8;
          font-size: 13px;
          margin: 0 0 12px 0;
        }
        .ai-toggle {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          color: #cdd6f4;
          font-size: 13px;
          cursor: pointer;
          user-select: none;
        }
        .ai-toggle input {
          accent-color: #89b4fa;
        }
        .quick-fix-button {
          background: #89b4fa;
          color: #1e1e2e;
          border: 0;
          border-radius: 6px;
          padding: 10px 14px;
          font-family: inherit;
          font-size: 13px;
          font-weight: bold;
          cursor: pointer;
        }
        .quick-fix-button:disabled {
          opacity: 0.5;
          cursor: not-allowed;
        }
        .quick-fix-button.hidden {
          display: none;
        }
        .apply-ai-button {
          background: #a6e3a1;
          color: #1e1e2e;
          border: 0;
          border-radius: 6px;
          padding: 10px 14px;
          font-family: inherit;
          font-size: 13px;
          font-weight: bold;
          cursor: pointer;
        }
        .apply-ai-button:disabled {
          opacity: 0.5;
          cursor: not-allowed;
        }
        .ai-apply-row {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: 12px;
          margin-top: 12px;
        }
        .ai-apply-row.hidden {
          display: none;
        }
        .editor-preference {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          color: #a6adc8;
          font-size: 12px;
        }
        .bugsage-editor-preference {
          background: #1e1e2e;
          color: #cdd6f4;
          border: 1px solid #45475a;
          border-radius: 6px;
          padding: 8px 10px;
          font-family: inherit;
          font-size: 12px;
        }
        .ai-code-preview {
          background: #1e1e2e;
          border: 1px solid #45475a;
          border-radius: 6px;
          padding: 12px;
          margin-top: 12px;
          color: #a6e3a1;
          font-size: 12px;
          white-space: pre-wrap;
          overflow-x: auto;
        }
        .ai-code-preview.hidden {
          display: none;
        }
        .ai-status {
          margin-top: 12px;
          color: #a6adc8;
          font-size: 13px;
          min-height: 0;
        }
        .ai-status.loading {
          color: #f9e2af;
        }
        .ai-status.error {
          color: #f38ba8;
        }
        .ai-notes.hidden {
          display: none;
        }
        #{AiChat.styles}
      CSS
    end

    def self.render_script
      loading_steps = Bugsage.t("ui.ai_panel.loading_steps")

      <<~HTML
        <script>
          (function () {
            if (window.__bugsageAiInitialized) return;
            window.__bugsageAiInitialized = true;

            var STORAGE_KEY = "bugsage-ai-enabled";
            var EDITOR_KEY = "bugsage-preferred-editor";
            var LOADING_STEPS = #{JSON.generate(loading_steps)};
            var THINKING = #{JSON.generate(Bugsage.t("ui.ai_panel.thinking"))};
            var CHAT_REQUEST_FAILED = #{JSON.generate(Bugsage.t("ui.ai_panel.chat_request_failed"))};
            var CODE_PATCH_UPDATED = #{JSON.generate(Bugsage.t("ui.ai_panel.code_patch_updated"))};
            var CONFIRM_APPLY_AI = #{JSON.generate(Bugsage.t("ui.ai_panel.confirm_apply_ai"))};
            var APPLYING = #{JSON.generate(Bugsage.t("ui.ai_panel.applying"))};
            var COULD_NOT_APPLY_AI = #{JSON.generate(Bugsage.t("ui.ai_panel.could_not_apply_ai"))};
            var APPLIED = #{JSON.generate(Bugsage.t("ui.ai_panel.applied"))};
            var NO_CODE_CHANGE = #{JSON.generate(Bugsage.t("code_patch.no_change"))};
            var REQUESTING_AI = #{JSON.generate(Bugsage.t("ui.ai_panel.requesting_ai"))};
            var AI_ENHANCED_APPLIED = #{JSON.generate(Bugsage.t("ui.ai_panel.ai_enhanced_applied"))};
            var SUGGESTION_UPDATED = #{JSON.generate(Bugsage.t("ui.ai_panel.suggestion_updated"))};
            var CONFIDENCE_SUFFIX = #{JSON.generate(Bugsage.t("ui.ai_panel.confidence_suffix"))};
            var ASSISTANT_WELCOME = #{JSON.generate(Bugsage.t("ui.ai_panel.assistant_welcome"))};
            var chatHistories = {};

            function aiEnabled() {
              return localStorage.getItem(STORAGE_KEY) !== "false";
            }

            function setAiEnabled(enabled) {
              localStorage.setItem(STORAGE_KEY, enabled ? "true" : "false");
            }

            function preferredEditor() {
              return localStorage.getItem(EDITOR_KEY) || "cursor";
            }

            function setPreferredEditor(value) {
              localStorage.setItem(EDITOR_KEY, value);
            }

            function panelSuffix(panel) {
              return panel.id.replace("bugsage-ai-panel", "");
            }

            function loadingOverlay(panel) {
              return document.getElementById("bugsage-ai-loading" + panelSuffix(panel));
            }

            function loadingStep(panel) {
              return document.getElementById("bugsage-ai-loading-step" + panelSuffix(panel));
            }

            var loadingTimers = {};

            function showLoading(panel) {
              var overlay = loadingOverlay(panel);
              var stepEl = loadingStep(panel);
              if (!overlay) return;

              panel.classList.add("is-loading");
              overlay.classList.remove("hidden");
              overlay.setAttribute("aria-hidden", "false");

              var stepIndex = 0;
              if (stepEl) stepEl.textContent = LOADING_STEPS[0];

              clearInterval(loadingTimers[panel.id]);
              loadingTimers[panel.id] = setInterval(function () {
                stepIndex = (stepIndex + 1) % LOADING_STEPS.length;
                if (stepEl) stepEl.textContent = LOADING_STEPS[stepIndex];
              }, 2200);
            }

            function hideLoading(panel) {
              var overlay = loadingOverlay(panel);
              if (!overlay) return;

              panel.classList.remove("is-loading");
              overlay.classList.add("hidden");
              overlay.setAttribute("aria-hidden", "true");
              clearInterval(loadingTimers[panel.id]);
            }

            function chatPanel(panel) {
              return document.getElementById("bugsage-ai-chat" + panelSuffix(panel));
            }

            function chatMessages(panel) {
              return document.getElementById("bugsage-ai-chat-messages" + panelSuffix(panel));
            }

            function chatHistoryKey(panel) {
              return panel.id + (panel.dataset.bugIndex !== undefined ? "-" + panel.dataset.bugIndex : "");
            }

            function appendChatBubble(container, role, text) {
              var bubble = document.createElement("div");
              bubble.className = "ai-chat-bubble " + role;
              bubble.textContent = text;
              container.appendChild(bubble);
              container.scrollTop = container.scrollHeight;
              return bubble;
            }

            function toggleChat(panel, forceOpen) {
              var chat = chatPanel(panel);
              if (!chat) return;

              var open = forceOpen === true || (forceOpen !== false && chat.classList.contains("hidden"));
              chat.classList.toggle("hidden", !open);
            }

            function sendChatMessage(panel, form) {
              var input = form.querySelector(".ai-chat-input");
              var sendButton = form.querySelector(".ai-chat-send");
              var messages = chatMessages(panel);
              if (!input || !messages) return;

              var message = input.value.trim();
              if (!message) return;

              var historyKey = chatHistoryKey(panel);
              var history = chatHistories[historyKey] || [];

              appendChatBubble(messages, "user", message);
              input.value = "";
              input.disabled = true;
              if (sendButton) sendButton.disabled = true;

              var loadingBubble = appendChatBubble(messages, "loading", THINKING);

              var payload = { message: message, history: history };
              if (panel.dataset.bugIndex !== undefined) {
                payload.index = parseInt(panel.dataset.bugIndex, 10);
              }

              fetch("#{AiChat::ENDPOINT}", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(payload)
              })
                .then(function (response) { return response.json(); })
                .then(function (result) {
                  loadingBubble.remove();
                  input.disabled = false;
                  if (sendButton) sendButton.disabled = false;
                  input.focus();

                  if (!result.ok) {
                    appendChatBubble(messages, "assistant", result.error || CHAT_REQUEST_FAILED);
                    return;
                  }

                  chatHistories[historyKey] = result.history || history;
                  appendChatBubble(messages, "assistant", result.reply || "");

                  if (result.code_patch) {
                    revealAiApply(panel, result);
                    var targets = panelTargets(panel);
                    if (targets && targets.status) {
                      targets.status.textContent = CODE_PATCH_UPDATED;
                      targets.status.className = "ai-status";
                    }
                  }
                })
                .catch(function (error) {
                  loadingBubble.remove();
                  input.disabled = false;
                  if (sendButton) sendButton.disabled = false;
                  appendChatBubble(messages, "assistant", error.message);
                });
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

            function revealAiApply(panel, result) {
              if (!result.code_patch && !result.code_fix) return;

              panel.dataset.codePatch = JSON.stringify(result.code_patch || {});
              panel.dataset.location = result.location || panel.dataset.location || "";

              var applyRow = panel.querySelector(".ai-apply-row");
              var preview = panel.querySelector(".ai-code-preview");
              if (result.code_patch && result.code_patch.action === "no_change") {
                if (applyRow) applyRow.classList.add("hidden");
                if (preview) {
                  preview.textContent = result.code_fix || NO_CODE_CHANGE;
                  preview.classList.remove("hidden");
                }
                return;
              }

              if (applyRow) applyRow.classList.remove("hidden");
              if (preview) {
                preview.textContent = result.code_fix || "";
                preview.classList.remove("hidden");
              }
            }

            function applyAiToCodebase(panel, button) {
              var location = panel.dataset.location;
              var codePatch = null;
              try {
                codePatch = JSON.parse(panel.dataset.codePatch || "null");
              } catch (error) {
                codePatch = null;
              }
              if (!location || !codePatch) return;

              if (!window.confirm(CONFIRM_APPLY_AI)) return;

              var originalText = button.textContent;
              button.disabled = true;
              button.textContent = APPLYING;

              fetch("#{FixApplicator::ENDPOINT}", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                  location: location,
                  code_patch: codePatch
                })
              })
                .then(function (response) { return response.json(); })
                .then(function (result) {
                  button.disabled = false;
                  button.textContent = originalText;
                  if (!result.ok) {
                    window.alert(result.error || COULD_NOT_APPLY_AI);
                    return;
                  }

                  var editor = panel.querySelector(".bugsage-editor-preference");
                  var choice = editor ? editor.value : preferredEditor();
                  setPreferredEditor(choice);

                  var editorUrl = result.editor_links && result.editor_links[choice];
                  if (editorUrl) openEditorUrl(editorUrl);

                  button.textContent = APPLIED;
                  setTimeout(function () { button.textContent = originalText; }, 2000);
                })
                .catch(function (error) {
                  button.disabled = false;
                  button.textContent = originalText;
                  window.alert(error.message);
                });
            }

            function panelTargets(panel) {
              var suffix = panel.id.replace("bugsage-ai-panel", "");
              var template = document.getElementById("bugsage-ai-targets" + suffix);
              if (!template) return null;

              return {
                fixes: document.querySelector(template.dataset.fixesTarget),
                confidence: document.querySelector(template.dataset.confidenceTarget),
                notes: document.querySelector(template.dataset.notesTarget),
                status: document.querySelector(template.dataset.statusTarget)
              };
            }

            function updateFixes(target, fixes) {
              if (!target) return;
              target.innerHTML = fixes.map(function (fix, index) {
                var selected = index === 0 ? " selected" : "";
                return "<li class=\\"" + selected.trim() + "\\">" + fix.replace(/</g, "&lt;").replace(/>/g, "&gt;") + "</li>";
              }).join("");
            }

            function syncToggle(panel) {
              var toggle = panel.querySelector(".bugsage-ai-toggle");
              var button = panel.querySelector(".bugsage-quick-fix");
              if (!toggle || !button) return;

              toggle.checked = aiEnabled();
              button.disabled = !toggle.checked;
            }

            document.querySelectorAll(".ai-panel").forEach(function (panel) {
              syncToggle(panel);
              var editorPick = panel.querySelector(".bugsage-editor-preference");
              if (editorPick) editorPick.value = preferredEditor();
            });

            document.addEventListener("change", function (event) {
              if (event.target.classList.contains("bugsage-editor-preference")) {
                setPreferredEditor(event.target.value);
              }
            });

            document.addEventListener("change", function (event) {
              if (!event.target.classList.contains("bugsage-ai-toggle")) return;

              var panel = event.target.closest(".ai-panel");
              setAiEnabled(event.target.checked);
              syncToggle(panel);
            });

            document.addEventListener("submit", function (event) {
              var form = event.target.closest(".bugsage-ai-chat-form");
              if (!form) return;

              event.preventDefault();
              var panel = form.closest(".ai-panel");
              if (!panel || !aiEnabled()) return;

              sendChatMessage(panel, form);
            });

            document.addEventListener("click", function (event) {
              var chatToggle = event.target.closest(".bugsage-ai-chat-toggle");
              if (chatToggle) {
                event.preventDefault();
                var chatPanelEl = chatToggle.closest(".ai-panel");
                if (chatPanelEl) toggleChat(chatPanelEl);
                return;
              }

              var chatClose = event.target.closest(".ai-chat-close");
              if (chatClose) {
                event.preventDefault();
                var closePanel = chatClose.closest(".ai-panel");
                if (closePanel) toggleChat(closePanel, false);
                return;
              }

              var applyAiButton = event.target.closest(".bugsage-apply-ai-codebase");
              if (applyAiButton) {
                event.preventDefault();
                var panel = applyAiButton.closest(".ai-panel");
                if (panel) applyAiToCodebase(panel, applyAiButton);
                return;
              }

              var button = event.target.closest(".bugsage-quick-fix");
              if (!button || button.disabled) return;

              var panel = button.closest(".ai-panel");
              var targets = panelTargets(panel);
              if (!targets || !targets.status) return;

              button.disabled = true;
              targets.status.textContent = REQUESTING_AI;
              targets.status.className = "ai-status loading";
              showLoading(panel);

              var payload = {};
              if (panel.dataset.bugIndex !== undefined) {
                payload.index = parseInt(panel.dataset.bugIndex, 10);
              }

              fetch("#{ENDPOINT}", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(payload)
              })
                .then(function (response) { return response.json(); })
                .then(function (result) {
                  hideLoading(panel);

                  if (!result.ok) {
                    targets.status.textContent = result.error;
                    targets.status.className = "ai-status error";
                    button.disabled = !aiEnabled();
                    return;
                  }

                  if (targets.fixes) {
                    updateFixes(targets.fixes, result.fixes || []);
                  }

                  var fixActions = panel.parentElement
                    ? panel.parentElement.querySelector(".fix-actions")
                    : document.querySelector(".fix-actions");
                  if (fixActions) {
                    fixActions.classList.remove("hidden");
                    if (result.location) {
                      fixActions.dataset.location = result.location;
                    }
                  }

                  revealAiApply(panel, result);

                  var rootCause = panel.closest(".bug-detail, .container");
                  if (rootCause) {
                    var message = rootCause.querySelector(".message-box p, .message-box");
                    if (message && result.root_cause) {
                      if (message.tagName === "P") {
                        message.textContent = result.root_cause;
                      }
                    }
                  }

                  if (targets.confidence) {
                    var confidenceText = result.confidence + "%";
                    if (targets.confidence.classList.contains("confidence-badge")) {
                      confidenceText += CONFIDENCE_SUFFIX;
                    }
                    targets.confidence.textContent = confidenceText;
                  }

                  if (targets.notes) {
                    if (result.ai_notes) {
                      targets.notes.textContent = result.ai_notes;
                      targets.notes.classList.remove("hidden");
                    } else {
                      targets.notes.classList.add("hidden");
                    }
                  }

                  targets.status.textContent = result.ai_enhanced
                    ? AI_ENHANCED_APPLIED
                    : SUGGESTION_UPDATED;
                  targets.status.className = "ai-status";
                  button.classList.add("hidden");

                  if (result.ai_notes || result.fixes) {
                    toggleChat(panel, true);
                    var messages = chatMessages(panel);
                    if (messages && messages.childElementCount === 0) {
                      appendChatBubble(
                        messages,
                        "assistant",
                        ASSISTANT_WELCOME
                      );
                    }
                  }
                })
                .catch(function (error) {
                  hideLoading(panel);
                  targets.status.textContent = error.message;
                  targets.status.className = "ai-status error";
                  button.disabled = !aiEnabled();
                });
            });
          })();
        </script>
      HTML
    end
  end
end
