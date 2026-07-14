#!/usr/bin/env bash
# Publish / refresh GitHub release notes for a tagged version.
# Usage: scripts/publish-github-release.sh [vX.Y.Z]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION="${1:-v0.2.0}"
NOTES_FILE="docs/releases/${VERSION}.md"

if [[ ! -f "$NOTES_FILE" ]]; then
  echo "Missing notes file: $NOTES_FILE" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "Install GitHub CLI: https://cli.github.com/" >&2
  exit 1
fi

TITLE="BugSage ${VERSION}"

if gh release view "$VERSION" --repo MONARCHKOLI/bugsage >/dev/null 2>&1; then
  echo "Updating existing release $VERSION…"
  gh release edit "$VERSION" \
    --repo MONARCHKOLI/bugsage \
    --title "$TITLE" \
    --notes-file "$NOTES_FILE"
else
  echo "Creating release $VERSION…"
  gh release create "$VERSION" \
    --repo MONARCHKOLI/bugsage \
    --title "$TITLE" \
    --notes-file "$NOTES_FILE"
fi

echo "Done: https://github.com/MONARCHKOLI/bugsage/releases/tag/${VERSION}"
