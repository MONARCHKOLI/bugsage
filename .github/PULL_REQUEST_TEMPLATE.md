## Description

<!-- Summarize what this PR changes and why. Focus on intent, not a file dump. -->

## Related Issue

<!-- Link the tracking issue. Use Fixes / Closes / Refs as appropriate. -->

- Fixes #
- Refs #

## Checklist

- [ ] I read [CONTRIBUTING.md](https://github.com/MONARCHKOLI/bugsage/blob/master/CONTRIBUTING.md)
- [ ] Branch follows `fix/` / `feat/` / `docs/` / `chore/` / `refactor/` / `test/` naming
- [ ] Commit messages use imperative summaries
- [ ] Diff is focused (no unrelated formatting sweeps)
- [ ] No secrets, API keys, or credentials are included
- [ ] Docs updated when user-facing behavior changed (`README.md`, `docs/`, and/or `CHANGELOG.md` `[Unreleased]`)
- [ ] Public API / architecture impact noted (see [ARCHITECTURE.md](https://github.com/MONARCHKOLI/bugsage/blob/master/ARCHITECTURE.md) if relevant)

### Type of change

- [ ] Bug fix
- [ ] New feature
- [ ] Documentation
- [ ] Refactor / chore
- [ ] Tests only
- [ ] CI / tooling

## Testing

<!-- How did you verify this? List commands and manual steps a reviewer can repeat. -->

- [ ] `bundle exec rake` passes locally (RSpec + RuboCop)
- [ ] Added or updated specs for behavior changes
- [ ] Manual verification (check all that apply):
  - [ ] Error page
  - [ ] `/bugsage` dashboard
  - [ ] HTTP error capture / API response passthrough
  - [ ] AI Quick Fix / Chat / Apply patch
  - [ ] Inline console
  - [ ] CLI / installer

**Commands run:**

```bash
bundle exec rake
# add other commands you ran
```

**Notes:**

<!-- Edge cases covered, known gaps, or environments tested (Ruby/Rails versions). -->

## Screenshots

<!-- Required for UI changes (error page, dashboard, AI panel). Otherwise write N/A. -->

| Before | After |
|--------|-------|
|        |       |

## Breaking Changes

<!-- Does this require action from existing users? -->

- [ ] No breaking changes
- [ ] Yes — describe impact and migration below

**Details (if yes):**

<!-- Example: config key renamed, default capture behavior changed, endpoint removed. -->
