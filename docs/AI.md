# AI

BugSage can optionally refine rule-based suggestions with OpenAI or Cursor. AI is **on-demand**: the error page stays fast, and the provider is called only when you click **Quick Fix Suggestion** or send a **Chat** message.

Related docs: [GettingStarted.md](GettingStarted.md) · [Configuration.md](Configuration.md) · [Troubleshooting.md](Troubleshooting.md)

## Enable AI

### 1. Provide an API key

In the same shell that starts Rails:

```bash
# OpenAI
export OPENAI_API_KEY=sk-your-openai-key-here

# or Cursor
export CURSOR_API_KEY=crsr_your-cursor-key-here

bin/rails server
```

Alternate variable names:

| Provider | Environment variables |
|----------|------------------------|
| OpenAI | `OPENAI_API_KEY`, `BUGSAGE_OPENAI_API_KEY` |
| Cursor | `CURSOR_API_KEY`, `BUGSAGE_CURSOR_API_KEY` |

### 2. Confirm the panel appears

On the BugSage error page or `/bugsage` dashboard you should see the **AI Suggestions** panel when AI is enabled.

If no key is present, BugSage continues to work with rule-based suggestions only.

### 3. Use Quick Fix and Chat

1. Toggle **Enable AI** if your browser session has it turned off (`localStorage`).
2. Click **Quick Fix Suggestion**.
3. Wait for the loading animation (Cursor can take longer — up to ~90 seconds).
4. Review fixes, AI notes, and the `code_patch` preview.
5. Optionally open **Chat** to refine the patch (for example, “comment out that line instead of deleting it”).
6. On the dashboard, use **Apply AI to Codebase** to write the latest patch to disk.

## Provider selection

| Situation | Provider used |
|-----------|---------------|
| `config.bugsage.ai_provider = :openai` | OpenAI |
| `config.bugsage.ai_provider = :cursor` | Cursor |
| Key starts with `crsr_` | Cursor (auto) |
| Key starts with `sk-` / other OpenAI keys | OpenAI (auto) |
| Cursor key stored in `OPENAI_API_KEY` | Cursor (prefix detected) |

Explicit config example:

```ruby
Rails.application.configure do |config|
  config.bugsage.ai_enabled = true
  config.bugsage.ai_provider = :cursor
  # config.bugsage.cursor_model = "composer-2.5"  # optional
end
```

OpenAI model example:

```ruby
Rails.application.configure do |config|
  config.bugsage.ai_provider = :openai
  config.bugsage.openai_model = "gpt-4o-mini"
  config.bugsage.openai_api_base = "https://api.openai.com/v1"
end
```

## What AI receives

When you request a Quick Fix, BugSage sends:

- Exception class and message
- Numbered source context around the failure (±20 lines)
- Request context (path, controller, action, parameters when available)
- Current rule-based classification

Chat continues from that context and can return an updated `code_patch`.

## Structured code patches

AI responses should include a surgical `code_patch` instead of blind search/replace:

| Action | Meaning |
|--------|---------|
| `delete_lines` | Remove one or more lines |
| `replace_lines` | Replace specific lines (for example comment out code) |
| `insert_before` | Insert code before a line |
| `no_change` | File already contains the correct fix |

BugSage:

- Uses absolute line numbers from numbered source context
- Rejects patches that would duplicate existing code
- Preserves indentation when applying

Chat-refined patches update the preview and the **Apply AI to Codebase** action. They are also persisted in the session store so the latest patch is used on apply.

## Dashboard AI actions

Available on `/bugsage` (not all actions appear on the full-page error view):

| Action | Purpose |
|--------|---------|
| **Quick Fix Suggestion** | Request AI analysis |
| **Chat** | Follow up and refine the patch |
| **Apply AI to Codebase** | Write the current `code_patch` to the source file |
| **Open in Cursor** / **Open in VS Code** | Jump to file and line |
| **Copy Fix** | Copy a prompt for your editor AI |
| **Apply Fix to File** | Insert a `# BUGSAGE:` comment (non-AI helper) |

**Apply AI to Codebase** / apply-fix endpoints are limited to **development** and **test**.

## Timeouts

| Provider | Default behavior |
|----------|------------------|
| OpenAI | `ai_timeout` default `15` seconds |
| Cursor | Effective timeout is at least `90` seconds (`[ai_timeout, 90].max`) |

Cursor runs through the [Cloud Agents API](https://cursor.com/docs/cloud-agent/api/endpoints) and often needs the longer window on the first response.

```ruby
config.bugsage.ai_timeout = 120
```

## Disable AI

```ruby
Rails.application.configure do |config|
  config.bugsage.ai_enabled = false
end
```

Or simply unset the API keys before starting the server.

## Failure behavior

If the AI API fails (invalid key, rate limit, timeout, network error):

- BugSage keeps the rule-based suggestion
- A warning is logged, for example:

```text
[BugSage] AI enhancement failed: ...
```

The error page and dashboard remain usable without AI.

## Related API endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/bugsage/ai-suggest` | `POST` | Quick Fix |
| `/bugsage/ai-chat` | `POST` | Chat + optional patch update |
| `/bugsage/apply-fix` | `POST` | Apply `code_patch` (dev/test only) |

## Related

- [Configuration.md](Configuration.md) — all AI-related options
- [Troubleshooting.md](Troubleshooting.md) — AI-specific failures
