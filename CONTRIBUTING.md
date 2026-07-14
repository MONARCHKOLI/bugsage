# Contributing to BugSage

Thank you for your interest in contributing to BugSage. This guide covers how to set up the project, run checks, and submit changes that are easy to review and merge.

Bug reports, documentation improvements, bug fixes, and new features are all welcome. By participating, you agree to follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## Table of contents

- [Development setup](#development-setup)
- [Running tests](#running-tests)
- [Coding standards](#coding-standards)
- [Project layout](#project-layout)
- [Branch naming](#branch-naming)
- [Commit message conventions](#commit-message-conventions)
- [Pull request guidelines](#pull-request-guidelines)
- [Reporting bugs](#reporting-bugs)
- [Suggesting features](#suggesting-features)
- [Release notes](#release-notes)

## Development setup

### Requirements

- **Ruby** `>= 3.2.0` (CI currently runs on Ruby 3.4)
- **Bundler**
- Git

### Clone and install

```bash
git clone https://github.com/MONARCHKOLI/bugsage.git
cd bugsage
bundle install
```

### Verify the setup

```bash
bundle exec rake
```

This runs the full default suite: RSpec and RuboCop. Both must pass before you open a pull request.

### Optional: local Rails app

To manually exercise middleware, the error page, or the `/bugsage` dashboard, add this gem to a Rails app via path or Git:

```ruby
# In the host app Gemfile
gem "bugsage", path: "/absolute/path/to/bugsage"
# or
gem "bugsage", github: "MONARCHKOLI/bugsage", branch: "your-branch"
```

Then run `bundle install` and restart the Rails server.

## Running tests

BugSage uses [RSpec](https://rspec.info/). Specs live under `spec/`.

### Full suite

```bash
bundle exec rake spec
# or
bundle exec rspec
```

### Focused examples

```bash
bundle exec rspec spec/bugsage_spec.rb
bundle exec rspec spec/bugsage_spec.rb -e "captures API bad request"
```

### Default Rake task

```bash
bundle exec rake
```

Runs **specs** and **RuboCop**. Prefer this before pushing.

### What to cover

When you change behavior, add or update specs that cover:

- happy path and important edge cases
- Rails-like response bodies (for example enumerable Rack bodies that do not implement `map`)
- configuration flags that alter capture or rendering
- i18n keys if you introduce or rename user-facing strings

Avoid committing secrets (API keys, credentials) in specs or fixtures.

## Coding standards

### Style and linting

- Style is enforced by [RuboCop](https://rubocop.org/) using `.rubocop.yml`
- Target Ruby version is **3.2**
- Prefer **double-quoted** strings (enforced by RuboCop)

```bash
bundle exec rubocop
# or via Rake (uses .rubocop.yml and --force-exclusion)
bundle exec rake rubocop
```

Auto-correct safe offenses when appropriate:

```bash
bundle exec rubocop -A
```

Do not weaken RuboCop rules or add broad excludes unless there is a clear, documented reason.

### Ruby practices

- Keep `# frozen_string_literal: true` at the top of Ruby files
- Prefer small, focused modules under `lib/bugsage/`
- Match existing naming, error handling, and middleware patterns
- Prefer deterministic rules first; AI-related code should degrade gracefully when keys or providers are unavailable

### User-facing strings

User-visible copy should go through `Bugsage.t` and live in `lib/bugsage/locales/en.yml` (or additional locale files). Avoid new hard-coded UI strings in Ruby or embedded HTML helpers unless they are truly non-user-facing (for example internal AI system prompts).

### Security and safety

- Do not commit API keys, tokens, or credentials
- Apply-fix / filesystem write paths must remain limited to development and test
- Prefer fixes that preserve API response bodies when capturing HTTP errors (do not replace successful or intentional JSON/XML responses with BugSage HTML unless that is the intended error-page path)

## Project layout

| Path | Purpose |
|------|---------|
| `lib/bugsage/` | Gem implementation |
| `lib/bugsage/locales/` | I18n strings |
| `lib/bugsage/railtie.rb` | Rails integration |
| `spec/` | RSpec suite |
| `exe/` | CLI entrypoints |
| `.rubocop.yml` | Lint configuration |
| `Rakefile` | `spec`, `rubocop`, and default task |
| `.github/workflows/` | CI |

## Branch naming

Create a branch from the latest `master`:

```bash
git checkout master
git pull origin master
git checkout -b <type>/<short-description>
```

### Recommended prefixes

| Prefix | Use for |
|--------|---------|
| `fix/` | Bug fixes |
| `feat/` | New features |
| `docs/` | Documentation only |
| `chore/` | Tooling, deps, CI, housekeeping |
| `refactor/` | Internal restructuring without behavior change |
| `test/` | Spec-only improvements |
| `perf/` | Performance improvements |

### Examples

```text
fix/rack-body-extract
feat/http-error-capture
docs/contributing-guide
chore/bump-rubocop
```

Keep names lowercase, hyphen-separated, and short.

## Commit message conventions

Write commits that explain **why** the change exists. Prefer one logical change per commit.

### Format

```text
<Imperative summary in sentence case>

Optional body explaining motivation, trade-offs, or follow-ups.
```

### Summary line

- Use the imperative mood: “Add…”, “Fix…”, “Capture…”, not “Added” or “Fixes”
- Keep the first line around **72 characters or fewer**
- Do not end the summary with a period
- Scope one concern per commit when practical

### Optional conventional prefixes

These prefixes appear in the history and are welcome when they clarify intent:

| Prefix | Meaning |
|--------|---------|
| `feat:` | New user-facing capability |
| `fix:` | Bug fix |
| `docs:` | Documentation |
| `chore:` | Maintenance |
| `refactor:` | Code change without behavior change |
| `test:` | Tests only |

### Good examples

```text
Fix Rack body extraction for ActionDispatch::Response::RackBody

Rails API responses implement each but not map. Iterating with each
avoids NoMethodError when capturing HTTP error bodies.
```

```text
feat: add HTTP 4xx/5xx capture for API responses
```

```text
docs: add CONTRIBUTING.md with setup and PR guidelines
```

### Avoid

- Vague messages: `update`, `fix stuff`, `wip`
- Mixing unrelated refactors with feature work in the same commit
- Committing generated noise (for example local `.rspec_status`) unless intentionally required

## Pull request guidelines

### Before you open a PR

1. Rebase or merge the latest `master` into your branch
2. Run `bundle exec rake` locally and ensure it passes
3. Add or update specs for behavior changes
4. Update docs (`README.md`, `CHANGELOG.md` under `[Unreleased]`) when user-facing behavior changes
5. Keep the diff focused; split large work into smaller PRs when possible

### PR title

Use the same style as commit summaries, for example:

```text
Fix Rack body extraction for Rails API responses
```

### PR description

Include:

- **Summary** — what changed and why
- **Test plan** — commands you ran and any manual steps (Postman, dummy Rails app, dashboard checks)
- **Screenshots** — for UI changes (error page, dashboard, AI panel)
- **Breaking changes** — call them out clearly, or state “None”

### Review expectations

- CI must pass (`.github/workflows/ci.yml`: RSpec, RuboCop, bundle-audit, gem build/validate)
- Prefer small, reviewable PRs
- Respond to review feedback with follow-up commits rather than force-pushing rewritten history unless asked
- Do not include unrelated formatting sweeps

### Merging

Maintainers typically merge after approval and green CI. Squash or merge strategy is up to maintainers; keep your branch history clean enough that either option works.

## Reporting bugs

Open an issue on GitHub with:

- BugSage version (or Git commit SHA if using the gem from Git)
- Ruby and Rails versions
- Minimal reproduction steps
- Expected vs actual behavior
- Relevant logs or stack traces (redact secrets)
- Whether AI features or HTTP error capture were enabled

## Suggesting features

Open an issue describing:

- the problem you want to solve
- proposed behavior
- alternatives considered
- whether it affects the default zero-config Rails experience

Features that change default middleware behavior (for example capturing non-exception HTTP responses) should document opt-out configuration when appropriate.

## Release notes

User-facing changes should be noted under `[Unreleased]` in `CHANGELOG.md` using Keep a Changelog–style sections (`Added`, `Changed`, `Fixed`, `Removed`). Maintainers handle version bumps and gem releases using [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md).

## Questions

If something in this guide is unclear, open a GitHub issue or start a discussion on the related pull request. Thanks for helping improve BugSage.
