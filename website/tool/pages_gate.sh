#!/usr/bin/env bash
# Decide whether a push to main should redeploy the website.
#
#   pages_gate.sh [pubspec] [latest-tag]
#
# Prints deploy=true|false, also appended to $GITHUB_OUTPUT when set.
set -euo pipefail

pubspec="${1:-packages/nesd/pubspec.yaml}"
repo="${GITHUB_REPOSITORY:-jpjonte/NESd}"

version=$(sed -n 's/^version:[[:space:]]*//p' "$pubspec" | head -n 1)
version="${version%%+*}"

if [ -z "$version" ]; then
  echo "pages_gate: no version in $pubspec" >&2
  exit 1
fi

latest="${2:-$(gh api "repos/$repo/releases/latest" --jq .tag_name)}"

if [ "$version" = "$latest" ]; then
  deploy=true
  reason="pubspec $version is the latest release"
else
  deploy=false
  reason="pubspec $version is not released yet (latest is $latest); the tag run deploys"
fi

echo "pages_gate: $reason"
echo "deploy=$deploy"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "deploy=$deploy" >> "$GITHUB_OUTPUT"
fi
