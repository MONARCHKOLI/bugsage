# Getting Started

This guide walks you through installing BugSage in a Rails app and verifying that exception capture, the error page, and the session dashboard work.

For configuration details, see [Configuration.md](Configuration.md). For AI setup, see [AI.md](AI.md). If something does not work, see [Troubleshooting.md](Troubleshooting.md).

## Requirements

- Ruby `>= 3.2`
- A Rails application

## Install the gem

### From RubyGems

```ruby
# Gemfile
gem "bugsage"
```

### From GitHub

```ruby
# Gemfile
gem "bugsage", github: "MONARCHKOLI/bugsage", branch: "master"
```

### From a local path (gem development)

```ruby
# Gemfile
gem "bugsage", path: "../bugsage"
```

Then install:

```bash
bundle install
```

## Start Rails

```bash
bin/rails server
```

BugSage wires itself through `Bugsage::Railtie`. You do **not** need to:

- edit `config/routes.rb`
- insert middleware manually
- change `config/application.rb` for basic use

## Verify exception capture

1. Trigger an exception in development (for example, call a method on `nil` in a controller action).
2. Confirm you see the **BugSage error page** instead of the default Rails debugger page.
3. Confirm the page shows:
   - exception class and message
   - highlighted source near the failure
   - suggested fixes and a confidence score
   - Rails request context

## Open the session dashboard

Visit:

```text
http://localhost:3000/bugsage
```

You should see the error you just triggered listed in the session store.

The dashboard is enabled by default in **development** only.

## Optional: generate an initializer

Only needed when you want documented overrides in your app:

```bash
bundle exec rails generate bugsage:install
```

Or:

```bash
bundle exec bugsage install
```

Guide only (no files written):

```bash
bundle exec bugsage install --guide-only
```

## Optional: enable AI

Export a key in the **same terminal** that starts Rails:

```bash
export OPENAI_API_KEY=sk-your-openai-key-here
# or
export CURSOR_API_KEY=crsr_your-cursor-key-here

bin/rails server
```

Then on the error page or dashboard:

1. Toggle **Enable AI** if needed.
2. Click **Quick Fix Suggestion**.
3. Optionally use **Chat** to refine the fix.
4. Use **Apply AI to Codebase** on the dashboard when you are ready.

Full details: [AI.md](AI.md).

## Optional: HTTP API error capture

BugSage can record HTTP status ≥ 400 responses (for example `render json: ..., status: :bad_request`) in the dashboard **without** changing the response body returned to Postman or other clients.

After calling a failing API endpoint, open `/bugsage` to see the captured HTTP error entry.

To disable:

```ruby
config.bugsage.capture_http_errors = false
```

## What gets auto-wired

On boot, BugSage typically enables:

| Capability | Default (development) |
|------------|------------------------|
| Exception capture middleware | On |
| HTML error page | On |
| Session dashboard (`/bugsage`) | On |
| Inline Rails console | On |
| HTTP error capture | On (when error capture is on) |
| Routing error capture (`exceptions_app`) | On |
| AI panel | On when an API key is present |

## Next steps

- Tune options in [Configuration.md](Configuration.md)
- Set up providers and patches in [AI.md](AI.md)
- Diagnose common issues in [Troubleshooting.md](Troubleshooting.md)
