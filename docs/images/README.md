# Image assets

## Logo & social

| File | Shows |
|------|--------|
| `BugSage_Logo.png` | Project logo / wordmark banner (magnifying-glass bug + BugSage) |
| `BugSage_Social_Preview.png` | GitHub / social Open Graph image — logo, tagline, feature grid, dashboard preview |

### Set the GitHub Social Preview

GitHub does not auto-detect this file. After committing:

1. Open [Repository Settings → General → Social preview](https://github.com/MONARCHKOLI/bugsage/settings)
2. Upload `docs/images/BugSage_Social_Preview.png`
3. Save

GitHub recommends about **1280×640** px (minimum ~640×320). This asset also works when sharing the repo on X, LinkedIn, and Slack.

## Screenshots

PNG captures used by the root [README.md](../README.md) **Screenshots** section. Most were taken from [`examples/sample_app`](../examples/sample_app).

| File | Shows |
|------|--------|
| `NoMethodError2.png` | Exception page for `GET /boom` |
| `NoMethodError.png` | Dashboard detail + AI Suggestions for `NoMethodError` |
| `BadRequest.png` | Dashboard detail for captured `HTTP 400 Response` |
| `BadRequest2.png` | Raw JSON body still returned by `GET /bad_request` |

## Still useful to add

| File | Suggested capture |
|------|-------------------|
| `cli-usage.png` | Terminal output for `bugsage version` / `bugsage install` |
| `ai-suggestions-chat.png` | Optional: Quick Fix result + follow-up chat with code patch |

Tips: crop to the relevant UI, avoid secrets, keep width readable on GitHub (~1200–1600px).
