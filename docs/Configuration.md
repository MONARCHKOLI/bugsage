# Configuration

BugSage is designed for zero configuration. Use this guide when you need to override defaults.

Related docs: [GettingStarted.md](GettingStarted.md) · [AI.md](AI.md) · [Troubleshooting.md](Troubleshooting.md)

## How to configure

### Rails initializer (recommended)

```ruby
# config/initializers/bugsage.rb
Rails.application.configure do |config|
  config.bugsage.enabled_environments = %i[development test staging]
  config.bugsage.show_error_page = true
  config.bugsage.show_dashboard = true
  config.bugsage.ai_enabled = true
  config.bugsage.ai_provider = :cursor
end
```

Generate a commented starter file with:

```bash
bundle exec rails generate bugsage:install
```

### Runtime configuration

```ruby
Bugsage.configure do |config|
  config.ai_enabled = true
  config.openai_model = "gpt-4o-mini"
  config.capture_http_errors = false
end
```

### Environment variables

| Variable | Purpose |
|----------|---------|
| `BUGSAGE_ENABLED_ENVIRONMENTS` | Comma-separated environments (for example `development,test,staging`) |
| `OPENAI_API_KEY` / `BUGSAGE_OPENAI_API_KEY` | OpenAI key (`sk-...`) |
| `CURSOR_API_KEY` / `BUGSAGE_CURSOR_API_KEY` | Cursor key (`crsr_...`) |

Keys must be present in the environment of the process that starts `bin/rails server`.

Restart the Rails server after changing configuration or environment variables.

## Options reference

| Option | Default | Description |
|--------|---------|-------------|
| `enabled_environments` | `development`, `test` | Environments where BugSage runs |
| `show_error_page` | `true` in development only | Replace raised exceptions with the BugSage HTML page |
| `show_dashboard` | `true` in development only | Serve `GET /bugsage` |
| `show_inline_console` | `true` in development only | Enable the inline Rails console |
| `capture_errors` | `true` | Store caught errors in the in-memory session store |
| `capture_http_errors` | `true` | Capture HTTP status ≥ 400 when `capture_errors` is on |
| `ai_enabled` | auto (`true` when an API key is present) | Show the AI panel; does not call the API until Quick Fix / Chat |
| `ai_provider` | auto-detected | `:openai` or `:cursor` |
| `openai_api_key` | `nil` (env fallback) | OpenAI API key |
| `openai_model` | `gpt-4o-mini` | OpenAI model name |
| `openai_api_base` | `https://api.openai.com/v1` | OpenAI-compatible base URL |
| `cursor_api_key` | `nil` (env fallback) | Cursor API key |
| `cursor_model` | `nil` (account default) | Cursor Cloud Agents model |
| `cursor_api_base` | `https://api.cursor.com` | Cursor API base URL |
| `ai_timeout` | `15` (minimum `90` for Cursor) | Request/poll timeout in seconds |
| `ai_client` | `nil` | Custom AI client for tests or alternate providers |
| `ignored_paths` | `["/favicon.ico", "/apple-touch-icon.png", %r{\A/assets/}, ...]` | Paths (strings or regexps) that BugSage will never capture or display |
| `fallback_exceptions_app` | `nil` | Optional fallback Rack app for routing errors |

## Default behavior by environment

| Environment | Error page | Dashboard | Capture | AI (if configured) |
|-------------|------------|-----------|---------|--------------------|
| **development** | BugSage page | `/bugsage` | Yes | Available |
| **test** | Rails default | Off | Yes (silent) | Available |
| **production** | Off | Off | Off | Off |

BugSage is **off** in production unless you explicitly add `production` to `enabled_environments`. Even then, prefer keeping `show_error_page` and `show_dashboard` disabled in production.

## Common configuration recipes

### Enable BugSage in staging

```ruby
Rails.application.configure do |config|
  config.bugsage.enabled_environments = %i[development test staging]
end
```

Or:

```bash
export BUGSAGE_ENABLED_ENVIRONMENTS=development,test,staging
```

### Capture errors silently (no BugSage HTML page)

Useful when you want the dashboard/store without replacing Rails’ error UI:

```ruby
Rails.application.configure do |config|
  config.bugsage.show_error_page = false
  config.bugsage.capture_errors = true
end
```

### Disable HTTP response capture

```ruby
Rails.application.configure do |config|
  config.bugsage.capture_http_errors = false
end
```

### Customize ignored paths

By default BugSage skips `/favicon.ico`, Apple touch icons, and asset-pipeline paths (`/assets/`, `/packs/`, `/vite/`). Override to add your own:

```ruby
Bugsage.configure do |config|
  config.ignored_paths = [
    "/favicon.ico",
    "/robots.txt",
    "/health",
    %r{\A/assets/},
    %r{\A/packs/}
  ]
end
```

### Force OpenAI or Cursor

```ruby
Rails.application.configure do |config|
  config.bugsage.ai_enabled = true
  config.bugsage.ai_provider = :openai
  # or
  # config.bugsage.ai_provider = :cursor
end
```

### Turn AI off completely

```ruby
Rails.application.configure do |config|
  config.bugsage.ai_enabled = false
end
```

### Disable the dashboard or inline console

```ruby
Rails.application.configure do |config|
  config.bugsage.show_dashboard = false
  config.bugsage.show_inline_console = false
end
```

## Endpoints BugSage registers

These are served by BugSage middleware when the gem is enabled:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/bugsage` | `GET` | Session dashboard |
| `/bugsage/console` | `POST` | Inline console evaluation |
| `/bugsage/ai-suggest` | `POST` | Quick Fix AI request |
| `/bugsage/ai-chat` | `POST` | Follow-up chat / patch refinement |
| `/bugsage/apply-fix` | `POST` | Apply a `code_patch` (development/test only) |
| `/bugsage/clear` | `POST` | Clear session error store |

## Internationalization

User-facing strings ship in `lib/bugsage/locales/en.yml` and are read through `Bugsage.t`.

Host apps can override keys via Rails I18n (for example `config/locales/bugsage.en.yml`) using the same key structure under the `bugsage` namespace.

## Related

- [GettingStarted.md](GettingStarted.md) — install and verify
- [AI.md](AI.md) — providers, chat, and patches
- [Troubleshooting.md](Troubleshooting.md) — common problems
