#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

repo="${GITHUB_REPOSITORY:-jpjonte/NESd}"

mkdir -p build

gh api "repos/$repo/releases/latest" > build/release.json

echo "fetch_release: wrote build/release.json for $(jq -r .tag_name build/release.json)"
