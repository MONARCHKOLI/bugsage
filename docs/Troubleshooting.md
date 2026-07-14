# Troubleshooting

Common issues when installing or using BugSage, and how to resolve them.

Related docs: [GettingStarted.md](GettingStarted.md) · [Configuration.md](Configuration.md) · [AI.md](AI.md)

## Installation and loading

### BugSage does nothing after `bundle install`

**Checks:**

1. Confirm the gem is in the bundle:

   ```bash
   bundle show bugsage
   ```

2. Confirm you restarted `bin/rails server` after adding the gem.
3. Confirm the environment is enabled (default: `development`, `test` only).

```bash
echo $RAILS_ENV
echo $BUGSAGE_ENABLED_ENVIRONMENTS
```

If you are in `staging` or `production`, add that environment explicitly:

```bash
export BUGSAGE_ENABLED_ENVIRONMENTS=development,test,staging
```

### Changes to the gem path are not picked up

When using `gem "bugsage", path: "..."` or a GitHub branch:

```bash
bundle update bugsage
bin/rails restart
# or stop and start bin/rails server
```

Spring or another preloader can cache old code — stop Spring if needed: `bin/spring stop`.

## Error page and dashboard

### I still see the default Rails error page

Possible causes:

| Cause | Fix |
|-------|-----|
| Not in development | Use development, or set `show_error_page = true` for your env |
| BugSage disabled for this env | Add the env to `enabled_environments` |
| `show_error_page` forced off | Set `config.bugsage.show_error_page = true` |
| Exception handled by the app | BugSage only sees unhandled exceptions (and configured HTTP errors) |

### `/bugsage` returns 404 or an empty app page

- Dashboard defaults to **development** only (`show_dashboard`).
- Ensure middleware is loading (restart server after install).
- Visit exactly `/bugsage` (trailing slash `/bugsage/` is also accepted).

### Dashboard is empty after an API call from Postman

1. Confirm `capture_errors` and `capture_http_errors` are enabled (both default to on when BugSage is enabled).
2. Confirm the response status is **≥ 400**. Successful `200` responses are not captured as errors.
3. Confirm you are looking at the **same Rails process** session (restarting the server clears the in-memory store).
4. If you previously hit a BugSage middleware bug on body extraction, update to a build that iterates Rack bodies with `each` (not `map`).

Disable HTTP capture intentionally:

```ruby
config.bugsage.capture_http_errors = false
```

### `NoMethodError` on `map` for `ActionDispatch::Response::RackBody`

Older BugSage builds extracted response bodies with `body.map`. Rails API responses often implement `each` only.

**Fix:** upgrade BugSage to a version that collects body parts with `each`, then `bundle update bugsage` and restart.

## AI issues

### AI panel does not appear

1. Export a key in the **same terminal** that runs Rails:

   ```bash
   export OPENAI_API_KEY=sk-...
   # or
   export CURSOR_API_KEY=crsr_...
   bin/rails server
   ```

2. Confirm `config.bugsage.ai_enabled` is not `false`.
3. Confirm BugSage is enabled for the current environment.

### Quick Fix fails or times out

Look for:

```text
[BugSage] AI enhancement failed: ...
```

in the Rails log or server terminal.

| Symptom | Likely cause | What to try |
|---------|--------------|-------------|
| Auth / 401 errors | Invalid or expired key | Rotate the key; confirm prefix (`sk-` vs `crsr_`) |
| Timeouts with Cursor | Cloud Agent duration | Raise `ai_timeout` (Cursor uses at least 90s) |
| Wrong provider | Mis-detected key | Set `config.bugsage.ai_provider = :openai` or `:cursor` |
| Rate limits | Provider quota | Retry later or switch providers |

```ruby
config.bugsage.ai_timeout = 120
config.bugsage.ai_provider = :cursor
```

### Chat reply does not change **Apply AI to Codebase**

Chat must return a structured `code_patch` in the response. If the model only returns prose, the apply button keeps the previous Quick Fix patch.

Ask explicitly, for example: “Update the code_patch to comment out line N instead of deleting it.”

### Apply fix does nothing / is forbidden

`/bugsage/apply-fix` is allowed in **development** and **test** only. It will not write files in production-like environments.

## Inline console

### Console is missing

`show_inline_console` defaults to **development** only. Enable it explicitly if needed:

```ruby
config.bugsage.show_inline_console = true
```

Evaluate carefully — the console runs Ruby in the application process.

## Configuration not applying

1. Prefer `config/initializers/bugsage.rb` with:

   ```ruby
   Rails.application.configure do |config|
     config.bugsage.ai_enabled = false
   end
   ```

2. Restart the server after edits.
3. Remember: `BUGSAGE_ENABLED_ENVIRONMENTS` can override enabled environments at boot via auto-configuration.

## Logging and inspection

When diagnosing capture or AI failures, check:

- BugSage HTML error page
- `http://localhost:3000/bugsage`
- `log/development.log`
- The terminal running `bin/rails server`
- `[BugSage] AI enhancement failed: ...` warnings

## Still stuck?

1. Confirm Ruby `>= 3.2` and a supported Rails app.
2. Run the gem’s own checks if developing locally:

   ```bash
   bundle exec rake
   ```

3. Open a GitHub issue with:
   - BugSage version or Git commit SHA
   - Ruby / Rails versions
   - Steps to reproduce
   - Relevant logs (redact secrets)

For vulnerabilities, use [SECURITY.md](../SECURITY.md) instead of a public issue.
