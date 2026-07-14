# Release Checklist

Checklist for publishing a new **BugSage** version to RubyGems and GitHub. Follow every step unless a release manager explicitly skips an item with a written reason.

Replace `X.Y.Z` with the version you are releasing (example: `0.3.0`).

---

## 0. Preconditions

- [ ] You have maintainer access to [github.com/MONARCHKOLI/bugsage](https://github.com/MONARCHKOLI/bugsage)
- [ ] You have a RubyGems.org account with push rights for `bugsage`
- [ ] MFA is enabled on RubyGems (gemspec sets `rubygems_mfa_required`)
- [ ] Working tree is clean on an up-to-date `master` (or a release branch based on it)
- [ ] CI is green on the commit you intend to release (`.github/workflows/ci.yml`)
- [ ] No open blockers for this version (security issues, broken install path)

```bash
git checkout master
git pull origin master
git status
```

---

## 1. Tests

- [ ] Run the full default suite locally:

```bash
bundle install
bundle exec rake          # RSpec + RuboCop
# or separately:
bundle exec rspec
```

- [ ] Confirm CI matrix passed for Ruby **3.2**, **3.3**, and **3.4**
- [ ] Confirm **bundle-audit** job passed (no known vulnerable deps)
- [ ] If you touched HTTP capture, AI, or middleware: run focused examples and a manual smoke test

Failure here stops the release.

---

## 2. RuboCop

- [ ] Lint is clean with project config:

```bash
bundle exec rubocop --config .rubocop.yml --force-exclusion
```

- [ ] Do **not** disable cops or widen excludes solely to ship a release
- [ ] CI **RuboCop** job is green

---

## 3. README review

- [ ] Installation instructions still work (Gemfile, Git, path)
- [ ] Version badge / featured version references match `X.Y.Z` if hardcoded
- [ ] Configuration table matches `Bugsage::Configuration` defaults
- [ ] New user-facing behavior is documented (or linked under `docs/`)
- [ ] Links to CONTRIBUTING, SECURITY, ARCHITECTURE, ROADMAP, and docs are valid
- [ ] No secrets, private tokens, or broken example commands

Also skim:

- [ ] `docs/GettingStarted.md`
- [ ] `docs/Configuration.md` / `docs/AI.md` / `docs/Troubleshooting.md` (if the release touches those areas)
- [ ] `ARCHITECTURE.md` / `ROADMAP.md` status tables if milestones moved

---

## 4. Version bump

Single source of truth:

```ruby
# lib/bugsage/version.rb
module Bugsage
  VERSION = "X.Y.Z"
end
```

- [ ] Bump `Bugsage::VERSION` in `lib/bugsage/version.rb`
- [ ] Confirm `bugsage.gemspec` reads `Bugsage::VERSION` (do not hardcode a second version)
- [ ] Choose SemVer intentionally:
  - **MAJOR** — breaking public API / default behavior
  - **MINOR** — new features, backwards compatible
  - **PATCH** — bug fixes / docs-only release packaging
- [ ] Update gemspec metadata URIs if needed (especially `changelog_uri` branch name)

```bash
ruby -e 'require_relative "lib/bugsage/version"; puts Bugsage::VERSION'
```

---

## 5. CHANGELOG

Follow Keep a Changelog style in `CHANGELOG.md`:

- [ ] Move items from `## [Unreleased]` into `## [X.Y.Z] - YYYY-MM-DD`
- [ ] Group under `Added` / `Changed` / `Fixed` / `Deprecated` / `Removed` / `Security` as needed
- [ ] Leave an empty `## [Unreleased]` section at the top for the next cycle
- [ ] Write user-facing notes (why it matters), not only file lists
- [ ] Call out **breaking changes** explicitly

Example shape:

```markdown
## [Unreleased]

## [X.Y.Z] - YYYY-MM-DD

### Added
- ...

### Fixed
- ...
```

---

## 6. Build gem

- [ ] Build from a clean tree matching what will be tagged:

```bash
rm -rf pkg/
bundle exec rake build
ls -la pkg/bugsage-X.Y.Z.gem
```

- [ ] Validate gemspec / package (same checks CI runs):

```bash
ruby -e 'spec = Gem::Specification.load("bugsage.gemspec"); spec.validate; puts spec.full_name'
gem unpack pkg/bugsage-X.Y.Z.gem --target /tmp/bugsage-unpack
test -f /tmp/bugsage-unpack/bugsage-X.Y.Z/lib/bugsage.rb
test -f /tmp/bugsage-unpack/bugsage-X.Y.Z/exe/bugsage
```

- [ ] Confirm packaged files include locales, generators, and LICENSE; exclude `spec/`, `.github/`, etc.

---

## 7. Install locally

- [ ] Install the built `.gem` into a clean gem home or local path:

```bash
gem install pkg/bugsage-X.Y.Z.gem
bugsage version
# expect: BugSage vX.Y.Z
```

Or without polluting the default gemset:

```bash
gem install pkg/bugsage-X.Y.Z.gem --install-dir /tmp/bugsage-gemhome
GEM_HOME=/tmp/bugsage-gemhome GEM_PATH=/tmp/bugsage-gemhome \
  /tmp/bugsage-gemhome/bin/bugsage version
```

- [ ] `require "bugsage"` loads without Rails
- [ ] Uninstall the local test install when finished (optional cleanup)

---

## 8. Test on a fresh Rails application

Do **not** rely only on the development dummy app path.

- [ ] Generate a new Rails app (versions you claim to support):

```bash
rails new /tmp/bugsage_release_app --skip-javascript
cd /tmp/bugsage_release_app
```

- [ ] Add the **built gem** (not the git worktree) via path to the `.gem` contents or:

```ruby
# Gemfile
gem "bugsage", path: "/tmp/bugsage-unpack/bugsage-X.Y.Z"
# after: gem unpack pkg/bugsage-X.Y.Z.gem --target /tmp/bugsage-unpack
```

Prefer testing the unpacked package so you catch packaging mistakes.

- [ ] `bundle install` and `bin/rails server`
- [ ] Trigger an exception → BugSage error page appears in development
- [ ] Visit `http://localhost:3000/bugsage` → dashboard loads
- [ ] If this release touches them, verify:
  - [ ] HTTP 4xx capture (API `status: :bad_request`) without breaking the JSON body
  - [ ] AI panel appears only with a key; Quick Fix does not run automatically
  - [ ] `bundle exec rails generate bugsage:install` / `bundle exec bugsage install --guide-only`

Stop the release if zero-config install fails.

---

## 9. Commit, tag, and push

- [ ] Commit release metadata only (version, changelog, docs bumps):

```bash
git add lib/bugsage/version.rb CHANGELOG.md README.md docs/
git commit -m "$(cat <<'EOF'
Release vX.Y.Z

EOF
)"
```

- [ ] Create an annotated tag:

```bash
git tag -a vX.Y.Z -m "BugSage vX.Y.Z"
```

- [ ] Push commit and tag:

```bash
git push origin master
git push origin vX.Y.Z
```

- [ ] Confirm CI is green on the tagged commit / `master`

---

## 10. GitHub Release

Do **not** publish a bare tag with an empty body. Write human-readable release notes
(see `docs/releases/` — e.g. [`v0.2.0.md`](releases/v0.2.0.md)).

- [ ] Draft notes under `docs/releases/vX.Y.Z.md` with at least:

```markdown
## What's New

- …
```

Include product highlights (features users feel), not only file-level changelog bullets.
Link to `CHANGELOG.md` for the full detail list.

- [ ] Open [Releases → Draft a new release](https://github.com/MONARCHKOLI/bugsage/releases/new)
  or create from the CLI:

```bash
gh release create vX.Y.Z \
  --title "BugSage vX.Y.Z" \
  --notes-file docs/releases/vX.Y.Z.md
```

- [ ] Choose / confirm tag `vX.Y.Z`
- [ ] Title: `BugSage vX.Y.Z` (not only the raw tag)
- [ ] Body: paste or `--notes-file` the release notes (What's New + install + changelog link)
- [ ] Attach `pkg/bugsage-X.Y.Z.gem` only if you build it for distribution (keep `*.gem` / `pkg/` out of Git)
- [ ] Mark as pre-release only if intentionally unstable
- [ ] Publish the GitHub Release
- [ ] Confirm the release page renders: `https://github.com/MONARCHKOLI/bugsage/releases/tag/vX.Y.Z`

---

## 11. RubyGems publish

Final gate — only after GitHub tag/release (or immediately after tag if you publish then announce).

- [ ] Re-confirm you are publishing the exact built gem for `X.Y.Z`:

```bash
gem env home
gem build bugsage.gemspec   # or use existing pkg/bugsage-X.Y.Z.gem
gem push pkg/bugsage-X.Y.Z.gem
```

- [ ] Complete MFA / OTP when prompted
- [ ] Verify the gem page: [https://rubygems.org/gems/bugsage](https://rubygems.org/gems/bugsage)
- [ ] Verify install from RubyGems:

```bash
gem install bugsage -v X.Y.Z
bugsage version
```

- [ ] `allowed_push_host` must remain `https://rubygems.org`

**Never** `--force` yank unless following a security process. Prefer a new patch release for fixes.

---

## 12. Post-release

- [ ] Smoke-install from RubyGems in another fresh Rails app (`gem "bugsage", "X.Y.Z"`)
- [ ] Update any hardcoded version badges (README) if still pointing at the old version
- [ ] Confirm GitHub **Social preview** uses `docs/images/BugSage_Social_Preview.png` (Settings → General → Social preview)
- [ ] Close/milestone related GitHub issues and PRs
- [ ] Announce briefly if you have a channel ( Discussions / social ) — optional
- [ ] Confirm `## [Unreleased]` is ready for the next cycle
- [ ] Rest before starting the next major feature branch ☕

---

## Quick command strip (healthy release)

```bash
bundle exec rake
bundle exec bundle-audit check --update
# bump lib/bugsage/version.rb + CHANGELOG.md + docs/releases/vX.Y.Z.md
bundle exec rake build
gem install pkg/bugsage-X.Y.Z.gem
# unpack + install into a fresh rails app and smoke-test
git tag -a vX.Y.Z -m "BugSage vX.Y.Z"
git push origin master --follow-tags
gh release create vX.Y.Z --title "BugSage vX.Y.Z" --notes-file docs/releases/vX.Y.Z.md
gem push pkg/bugsage-X.Y.Z.gem
```

---

## Abort criteria

Do **not** publish if any of the following are true:

- Specs or RuboCop fail
- Bundle audit reports a relevant unpatched vulnerability in a runtime dependency
- Fresh Rails app does not see the error page / dashboard with zero-config
- Version / changelog / tag disagree
- You cannot complete RubyGems MFA

---

## Related docs

- [CONTRIBUTING.md](../CONTRIBUTING.md)
- [CHANGELOG.md](../CHANGELOG.md)
- [Release notes — v0.2.0](releases/v0.2.0.md)
- [SECURITY.md](../SECURITY.md)
- [ARCHITECTURE.md](../ARCHITECTURE.md)
- [ROADMAP.md](../ROADMAP.md)
- RubyGems: [Make your own gem](https://guides.rubygems.org/make-your-own-gem/) · [Publishing](https://guides.rubygems.org/publishing/)
