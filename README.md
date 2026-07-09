# BugSage

BugSage is a Ruby gem for Ruby on Rails applications that helps developers understand exceptions faster. Instead of showing only a raw stack trace, BugSage classifies the error, explains the likely root cause, and suggests actionable fixes.

It is designed to work as a lightweight debugging companion for development environments and can be used with Rails middleware to render a friendly, informative error page.

## What BugSage does

- Catches common Rails and Ruby exceptions
- Classifies them into likely issue categories
- Surfaces the root cause in a simple report
- Suggests practical next steps
- Displays Rails request context such as path, method, controller, action, and parameters

## Supported error handling

The current version handles common Ruby and Rails exceptions, including:

### Ruby exceptions
- `NoMethodError`
- `NameError`
- `ArgumentError`
- `TypeError`
- `RuntimeError`
- `StandardError`

### Rails / Active Record exceptions
- `ActionController::RoutingError`
- `ActionController::ParameterMissing`
- `ActionController::UnpermittedParameters`
- `ActiveRecord::RecordNotFound`
- `ActiveRecord::RecordInvalid`

### Generic fallback
- Any other exception inheriting from `StandardError` is also handled with a generic BugSage suggestion.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bugsage'
```

And then execute:

```bash
bundle install
```

## Usage

BugSage can be used by mounting the middleware in your Rails app or by requiring it in your development environment. When an exception is caught, BugSage renders a helpful page with:

- the exception name
- the location
- the message
- a suggested fix
- confidence score
- Rails request context

## How and where to check the logs

When BugSage catches an exception, you can inspect the information in the browser error page and in your local Rails logs.

### Common places to check

- Rails development log:
  - `log/development.log`
- Rails test log:
  - `log/test.log`
- Terminal output where you started the Rails server

### Typical steps

1. Start your Rails app locally.
2. Trigger the error in the browser or via a request.
3. Open the BugSage error page that appears for the exception.
4. Check your Rails log output in the terminal or in `log/development.log` for the full exception details.
5. If you want to inspect the captured event history, open the BugSage dashboard or review the in-memory store while the app is running.

## Rails application changes needed

To use BugSage in a Rails application, you usually need to make a few small application-side changes:

1. Add the gem to your Gemfile and install it.
2. Ensure the middleware is enabled in your Rails environment so exceptions are intercepted.
3. Make sure your app is running in development or test mode to see the BugSage error page.
4. If you want to inspect full request context, keep the standard Rails request data available in the Rack environment (path, params, request ID, host, and user agent).
5. If you want to see the error page in a browser, trigger an exception through a controller action or route.

In most cases, no major Rails code changes are required beyond installing the gem and enabling the middleware in your environment.

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
