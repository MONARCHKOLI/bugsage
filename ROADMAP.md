# BugSage Roadmap

This document describes where BugSage is today and where the project is headed. It is a living plan for contributors and users—not a contractual release schedule. Priorities may shift based on feedback, security needs, and community interest.

> **Current release:** [v0.2.0](CHANGELOG.md)  
> **Discuss ideas:** [GitHub Issues](https://github.com/MONARCHKOLI/bugsage/issues) · [Feature request template](https://github.com/MONARCHKOLI/bugsage/issues/new/choose)

---

## Vision

BugSage aims to be the fastest path from a Rails failure to a confident fix.

Today, developers often bounce between stack traces, logs, docs, and AI chat tools with little shared context. BugSage brings **classification, explanation, and actionable repair** into the development loop—starting with deterministic rules and layering optional AI only when you ask for it.

Long term, BugSage should feel like a coherent debugging companion across:

- Local Rails development (error pages, session dashboard, inline console)
- CI and pull requests (automated failure analysis)
- Editors (Cursor, VS Code, RubyMine)
- Background jobs and production-adjacent log workflows—always with clear safety boundaries

**Principles:**

1. **Rules first, AI second** — instant, predictable baselines; AI on demand
2. **Zero-config by default** — useful after `bundle install` in development
3. **Safe by design** — write actions limited to development/test; production opt-in only with careful defaults
4. **Open and extensible** — clear extension points for rules, providers, and plugins

---

## Current Status

BugSage **v0.2.x** is a development-focused Rails gem with:

| Capability | Status |
|------------|--------|
| Zero-config Railtie install | Shipped |
| Exception classification (Ruby / Rails rules) | Shipped |
| HTML error page + request context | Shipped |
| Session dashboard at `/bugsage` | Shipped (in-memory, per process) |
| Inline Rails console | Shipped |
| HTTP 4xx/5xx capture (API responses) | Shipped |
| On-demand AI (OpenAI / Cursor Cloud Agents) | Shipped |
| Follow-up AI chat + surgical `code_patch` | Shipped |
| Apply patch / editor deep links | Shipped (dev/test) |
| I18n-backed user-facing strings | Shipped |
| Community docs (README, CONTRIBUTING, SECURITY, `docs/`) | In progress / expanding |

**Not yet productized:** persistent production analytics, CI GitHub Action, editor extensions, deep Sidekiq/ActiveJob runtime integration beyond exception rules, Docker/log pipelines, or a formal plugin API.

---

## Short-term Goals (v0.2–v0.5)

Focus: harden the core gem, improve AI/editor workflows, and prepare for a trustworthy **v1.0**.

### v0.2.x (stability)

- Publish clear docs and community health files
- Expand RSpec coverage for public APIs (Store, CodePatch, HTTP capture edges, CLI)
- Gemspec / packaging polish for RubyGems release
- Bug fixes for Rack body handling, chat→apply patch flow, and edge-case capture

### v0.3 — Stronger AI error analysis

- Richer AI prompts with safer, more reliable `code_patch` schemas
- Better multi-file / multi-hunk patch previews
- Provider resilience (retries, clearer timeouts, offline fallback messaging)
- Optional “explain this HTTP 400 body” analysis from captured API errors

### v0.4 — Rails dashboard 2.0

- Persist session history across requests more usefully (optional file/SQLite/Redis store)
- Filtering, search, and grouping (by exception class, path, confidence)
- Clearer split between exception events and HTTP error events
- Export a single error as a shareable Markdown / clipboard report

### v0.5 — Jobs & CI foundations

- Deeper **ActiveJob** and **Sidekiq** error context (queue, job class, arguments sanitization)
- First **GitHub Action** prototype: annotate failing CI jobs with BugSage-style summaries
- Public **plugin-ready hooks** for custom rules (preview of the later plugin system)

---

## Mid-term Goals (v1.0)

**v1.0** marks BugSage as a stable, documented tool for day-to-day Rails development.

### Release criteria (target)

- SemVer stability commitments for public Ruby APIs (`Bugsage.configure`, rule result shape, patch schema)
- Comprehensive docs and examples
- Solid test matrix (Ruby 3.2+ × modern Rails)
- Official RubyGems release with MFA and security policy

### Headline v1.0 themes

| Theme | Outcome |
|-------|---------|
| **AI Error Analysis** | Dependable on-demand analysis with structured patches and chat refinement |
| **Rails Dashboard** | Polished session dashboard suitable as the default local error hub |
| **Cursor Integration** | First-class Cursor provider + deep links + smoother “open and apply” loop |
| **ActiveJob / Sidekiq Support** | First-class job failure context in dashboard and AI prompts |
| **GitHub Action** | Supported action for PR/CI failure comments (opt-in) |
| **Plugin System (v1)** | Documented API for custom rules and suggestion enrichers |

v1.0 remains **development-first**. Production deployment, if offered, will be explicit, limited, and separately documented.

---

## Long-term Goals (v2.0+)

**v2.0+** expands BugSage from an in-app development assistant into a broader debugging platform—without abandoning the rules-first identity.

| Theme | Direction |
|-------|-----------|
| **Log Analyzer** | Parse Rails / job logs into classified events offline or in CI |
| **Docker Logs** | Tail or batch-analyze container logs with the same rule engine |
| **Production Log Analysis** | Redacted, privacy-aware analysis pipelines (never default-on) |
| **Performance Analyzer** | Slow endpoints, N+1 hints, allocation hotspots as advisory findings |
| **Security Checks** | Opinionated checks for risky patterns (open redirects, unsafe eval in captured context, secret leakage in error pages) |
| **VS Code Extension** | Browse BugSage events, jump to frames, trigger explain/fix from the editor |
| **RubyMine Plugin** | Parity features for JetBrains workflows |
| **Plugin System (v2)** | Installable rule packs and provider plugins |
| **Ecosystem** | Shared formats for CI annotations, editor protocols, and report export |

These tracks are aspirational and may ship as companion repos (for example `bugsage-action`, `bugsage-vscode`) rather than inside the core gem.

---

## Planned Features

Status key: **Shipped** · **Partial** · **Planned** · **Exploratory**

| Feature | Status | Target window | Notes |
|---------|--------|---------------|-------|
| **AI Error Analysis** | Partial | v0.3 → v1.0 | On-demand OpenAI/Cursor + chat/patches shipped; depth & reliability ongoing |
| **Rails Dashboard** | Partial | v0.4 → v1.0 | Session UI shipped; persistence, filters, exports planned |
| **Cursor Integration** | Partial | v0.3 → v1.0 | Cloud Agents provider + editor links shipped; tighter UX planned |
| **ActiveJob Support** | Partial | v0.5 → v1.0 | Deserialization/rules exist; richer job metadata planned |
| **Sidekiq Support** | Planned | v0.5 → v1.0 | Failure middleware / context adapters |
| **GitHub Action** | Planned | v0.5 → v1.0 | CI annotations from test/job failures |
| **Plugin System** | Planned | v0.5 → v2.0 | Custom rules first; installable packs later |
| **VS Code Extension** | Planned | v2.0+ | Companion extension |
| **RubyMine Plugin** | Planned | v2.0+ | Companion plugin |
| **Log Analyzer** | Planned | v2.0+ | Offline/CI log → classified events |
| **Docker Logs** | Planned | v2.0+ | Container log ingestion |
| **Production Log Analysis** | Exploratory | v2.0+ | Strict redaction & opt-in only |
| **Performance Analyzer** | Exploratory | v2.0+ | Advisory performance findings |
| **Security Checks** | Exploratory | v1.0 → v2.0 | Start with safe defaults in error presentation |

---

## Nice-to-have Features

Ideas we like but are not committed to a milestone:

- Slack / Discord webhook summaries for local session digests
- Browser extension to pin the BugSage dashboard beside the app
- Multi-language UI beyond English locale files
- “Reproduction gist” exporter (redacted params + failing snippet)
- Webhook provider plugins (non–OpenAI/Cursor HTTP endpoints)
- Replayable fixture recorder for flaky request failures
- Metrics: time-to-fix estimates from historical session data (local only)
- Themeable error page / dashboard CSS tokens for host apps

Propose additions via a [feature request](https://github.com/MONARCHKOLI/bugsage/issues/new/choose).

---

## Community Contributions

BugSage welcomes contributions of all sizes. High-impact areas:

| Area | How to help |
|------|-------------|
| **Bug reports** | Use the bug report template; include Ruby/Rails/BugSage versions |
| **Rules** | Add deterministic matchers for common Rails/Ruby failures + specs |
| **Docs** | Improve `docs/`, README examples, and troubleshooting |
| **Tests** | Fill public API coverage gaps called out in reviews/issues |
| **AI providers** | Hardening, fixtures, and safer patch schemas |
| **Jobs** | Sidekiq / ActiveJob integrations with sanitized argument display |
| **Tooling** | GitHub Action, editor extensions (often as companion repos) |

### Getting started

1. Read [CONTRIBUTING.md](CONTRIBUTING.md)
2. Skim [docs/GettingStarted.md](docs/GettingStarted.md) (if present)
3. Open an issue before large features
4. Prefer small PRs with specs and changelog notes under `[Unreleased]`

### Security

Do **not** report vulnerabilities in public issues. Follow [SECURITY.md](SECURITY.md).

### Roadmap feedback

If a planned item should move up or down:

- Comment on an existing related issue, or
- Open a feature request describing user impact and whether it changes zero-config defaults

---

## Version legend

| Range | Intent |
|-------|--------|
| **v0.2–v0.5** | Iterate quickly; APIs may refine before 1.0 |
| **v1.0** | Stable core for Rails development workflows |
| **v2.0+** | Broader platform (logs, CI depth, editors, production-adjacent tools) |

---

*Last updated: July 2026. Maintainers will revise this file as milestones land.*
