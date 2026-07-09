# BugSage

BugSage is a Ruby gem for Ruby on Rails applications that helps developers understand exceptions faster. Instead of showing only a raw stack trace, BugSage classifies the error, explains the likely root cause, and suggests actionable fixes.

It uses deterministic rules first, with optional AI-powered refinement when enabled.

## What BugSage does

- Catches common Rails and Ruby exceptions
- Classifies them into likely issue categories
- Surfaces the root cause in a simple report
- Suggests practical next steps
- Optionally refines suggestions with OpenAI when configured
- Displays Rails request context such as path, method, controller, action, and parameters
- Provides a session dashboard at `/bugsage` in development

## Installation

Add this line to your application's Gemfile:

```ruby
gem "bugsage"
```

Then run:

```bash
bundle install
```

BugSage auto-wires itself through a Rails Railtie. You do **not** need to manually add middleware or change `routes.rb`.

## Configuration

Configure BugSage in `config/application.rb` (or an initializer) using `config.bugsage`:

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    config.bugsage.enabled_environments = %i[development test]
    config.bugsage.show_error_page = true
    config.bugsage.show_dashboard = true
    config.bugsage.capture_errors = true
    config.bugsage.ai_enabled = false
  end
end
```

You can also configure at runtime:

```ruby
Bugsage.configure do |config|
  config.ai_enabled = true
  config.openai_model = "gpt-4o-mini"
end
```

### Configuration options

| Option | Default | Description |
|--------|---------|-------------|
| `enabled_environments` | `development`, `test` | Environments where BugSage runs |
| `show_error_page` | `true` in development only | Replace errors with the BugSage HTML page |
| `show_dashboard` | `true` in development only | Serve the `/bugsage` session dashboard |
| `capture_errors` | `true` | Store caught errors in the in-memory session store |
| `ai_enabled` | `false` | Refine rule-based suggestions with OpenAI |
| `openai_api_key` | `nil` (falls back to env) | OpenAI API key |
| `openai_model` | `gpt-4o-mini` | Model used for AI analysis |
| `openai_api_base` | `https://api.openai.com/v1` | OpenAI-compatible API base URL |
| `ai_timeout` | `15` | OpenAI request timeout in seconds |
| `ai_client` | `nil` | Custom AI client (for testing or alternate providers) |

### Default behavior by environment

| Environment | Error page | Dashboard | Capture | AI (if enabled) |
|-------------|------------|-----------|---------|-----------------|
| **development** | BugSage page | `/bugsage` | Yes | Yes |
| **test** | Rails default | Off | Yes (silent) | Yes |
| **production** | Off (disabled) | Off | Off | Off |

Restart the Rails server after changing configuration.

### AI suggestions

When `ai_enabled` is `true` and an API key is available, BugSage:

1. Runs deterministic rules first (fast, offline)
2. Sends exception details and request context to OpenAI
3. Merges AI output into the suggestion (refined root cause, extra fixes, notes)
4. Falls back to rules-only if the API call fails

Set your API key via environment variable:

```bash
export OPENAI_API_KEY=sk-your-key-here
bin/rails server
```

BugSage also reads `BUGSAGE_OPENAI_API_KEY`. The key must be available in the **same terminal** that starts the Rails server.

When AI enhancement succeeds, the error page and dashboard show an **AI-enhanced** badge and **AI notes**. If the API fails (e.g. invalid key, rate limit), BugSage shows rule-based suggestions and logs:

```text
[BugSage] AI enhancement failed: ...
```

## Usage

When an exception is caught, BugSage renders a helpful page with:

- the exception name
- highlighted source code near the failure
- the message
- suggested fixes
- confidence score
- optional AI notes
- Rails request context

Open the session dashboard at:

```text
http://localhost:3000/bugsage
```

## Supported exceptions

BugSage handles many common Ruby and Rails exceptions, including:

### Ruby
- `NoMethodError`, `NameError`, `KeyError`, `ArgumentError`, `TypeError`
- `ZeroDivisionError`, `JSON::ParserError`, `FrozenError`, `RuntimeError`

### Rails / Active Record
- `ActionController::RoutingError`, `ActionController::ParameterMissing`
- `ActionController::UnpermittedParameters`, `ActionView::Template::Error`
- `ActiveRecord::RecordNotFound`, `ActiveRecord::RecordInvalid`
- `ActiveRecord::RecordNotUnique`, `ActiveRecord::StatementInvalid`
- `ActiveRecord::ConnectionNotEstablished`, and more

### Generic fallback
Any other `StandardError` receives a generic BugSage suggestion.

## How and where to check logs

When BugSage catches an exception, inspect:

- the BugSage error page in the browser
- the `/bugsage` dashboard for session history
- `log/development.log` or the terminal running `bin/rails server`
- `[BugSage] AI enhancement failed` warnings when AI is enabled but the API call fails

## Development

After checking out the repo, run:

```bash
bundle install
bundle exec rspec
```

## Contributing

Bug reports and pull requests are welcome.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

