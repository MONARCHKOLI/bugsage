# frozen_string_literal: true

require "json"

module Bugsage
  class InlineConsole
    extend JsonEndpoint

    def self.evaluate(code)
      return error_response("Console is not available for this error.") unless ConsoleContext.available?

      stripped = code.to_s.strip
      return error_response("Enter a Ruby expression to evaluate.") if stripped.empty?

      binding = ConsoleContext.binding_for_eval
      result = eval(stripped, binding, "(bugsage-console)", 1) # rubocop:disable Security/Eval

      success_response(result)
    rescue SyntaxError, StandardError => e
      error_response(format_exception(e))
    end

    def self.handle_request(env)
      return not_found unless Bugsage.configuration.show_inline_console?

      payload = parse_request_body(env)
      return json_response(error_response("Console is not available for this error.")) unless prepare_context!(payload)

      response = evaluate(payload["code"])
      json_response(response)
    end

    def self.prepare_context!(payload)
      return true unless payload.key?("index")

      load_context_for_index(payload["index"])
    end

    def self.load_context_for_index(index)
      event = Store.all[index.to_i]
      ConsoleContext.load_from_event(event)
    end

    def self.render_panel(bug_index: nil, include_script: true)
      return "" unless Bugsage.configuration.show_inline_console?

      suffix = bug_index.nil? ? "" : "-bug-#{bug_index}"
      output_id = "bugsage-console-output#{suffix}"
      input_id = "bugsage-console-input#{suffix}"
      index_attr = bug_index.nil? ? "" : %( data-bug-index="#{bug_index}")

      <<~HTML
        <div class="section inline-console">
          <div class="label">Inline Rails Console</div>
          <p class="console-help">
            Evaluate Ruby in the context of this error. Available locals:
            <code>exception</code>, <code>request_context</code>, <code>params</code>
          </p>
          <form
            class="console-form bugsage-console-form"
            data-output-target="#{output_id}"
            data-input-target="#{input_id}"#{index_attr}
          >
            <label class="console-prompt" for="#{input_id}">&gt;&gt;</label>
            <input
              id="#{input_id}"
              class="console-input"
              type="text"
              name="code"
              autocomplete="off"
              spellcheck="false"
              placeholder="exception.class"
            />
            <button type="submit" class="console-submit">Run</button>
          </form>
          <div id="#{output_id}" class="console-output" aria-live="polite"></div>
        </div>
        #{render_script if include_script}
      HTML
    end

    def self.styles
      <<~CSS
        .inline-console {
          background: #313244;
          border: 1px solid #45475a;
          border-radius: 8px;
          padding: 16px;
          margin-bottom: 20px;
        }
        .console-help {
          color: #a6adc8;
          font-size: 13px;
          margin: 0 0 12px 0;
        }
        .console-help code {
          color: #89b4fa;
        }
        .console-output {
          background: #1e1e2e;
          border: 1px solid #45475a;
          border-radius: 6px;
          min-height: 72px;
          max-height: 260px;
          overflow-y: auto;
          padding: 12px;
          margin-top: 12px;
        }
        .console-output:empty {
          display: none;
        }
        .console-line {
          white-space: pre-wrap;
          margin-bottom: 6px;
          font-size: 13px;
        }
        .console-line.input { color: #cdd6f4; }
        .console-line.result { color: #a6e3a1; }
        .console-line.error { color: #f38ba8; }
        .console-form {
          display: flex;
          align-items: center;
          gap: 8px;
        }
        .console-prompt {
          color: #a6e3a1;
          font-weight: bold;
        }
        .console-input {
          flex: 1;
          background: #1e1e2e;
          color: #cdd6f4;
          border: 1px solid #45475a;
          border-radius: 6px;
          padding: 10px 12px;
          font-family: inherit;
          font-size: 13px;
        }
        .console-input:focus {
          outline: none;
          border-color: #89b4fa;
        }
        .console-submit {
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
      CSS
    end

    def self.render_script
      <<~HTML
        <script>
          (function () {
            if (window.__bugsageConsoleInitialized) return;
            window.__bugsageConsoleInitialized = true;

            function appendLine(output, text, type) {
              var line = document.createElement("div");
              line.className = "console-line" + (type ? " " + type : "");
              line.textContent = text;
              output.appendChild(line);
              output.scrollTop = output.scrollHeight;
            }

            document.addEventListener("submit", function (event) {
              var form = event.target;
              if (!form.classList || !form.classList.contains("bugsage-console-form")) return;

              event.preventDefault();
              var input = document.getElementById(form.dataset.inputTarget);
              var output = document.getElementById(form.dataset.outputTarget);
              if (!input || !output) return;

              var code = input.value.trim();
              if (!code) return;

              appendLine(output, ">> " + code, "input");
              input.value = "";

              var payload = { code: code };
              if (form.dataset.bugIndex !== undefined) {
                payload.index = parseInt(form.dataset.bugIndex, 10);
              }

              fetch("/bugsage/console", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(payload)
              })
                .then(function (response) { return response.json(); })
                .then(function (result) {
                  appendLine(output, result.output, result.ok ? "result" : "error");
                })
                .catch(function (error) {
                  appendLine(output, error.message, "error");
                });
            });
          })();
        </script>
      HTML
    end

    def self.success_response(result)
      { ok: true, output: "=> #{format_value(result)}" }
    end

    def self.error_response(message)
      { ok: false, output: message.to_s }
    end

    def self.format_value(value)
      value.inspect
    end

    def self.format_exception(exception)
      "#{exception.class}: #{exception.message}"
    end
  end
end
