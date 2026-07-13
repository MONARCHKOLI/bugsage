## [Unreleased]

## [0.2.0] - 2026-07-13

### Added
- Zero-config Rails setup via `Bugsage::AutoConfigurator` on boot
- `rails generate bugsage:install` generator and `bundle exec bugsage install` CLI
- `Bugsage::Installation` guide with canonical install steps
- Inline Rails console on error page and `/bugsage` dashboard
- Optional AI-enhanced suggestions with OpenAI and Cursor providers
- Auto-detection of API key type (`sk-...` vs `crsr_...`) from environment variables
- Session dashboard at `/bugsage` with split-pane layout and source highlighting
- Env-based configuration through Rails Railtie and `config.bugsage`

### Changed
- AI is auto-enabled when an API key is present (override with `config.bugsage.ai_enabled = false`)
- README updated with step-by-step zero-config installation guide

## [0.1.1] - 2026-07-09

- Expanded Rails exception handling for routing, parameter, template, storage, Redis, Faraday, CSRF, flash, and signed-message errors
- Added regression coverage for the new exception categories

## [0.1.0] - 2026-07-08

- Initial release
