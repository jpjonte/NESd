#!/usr/bin/env bash
set -euo pipefail

repo="$1"
shift

# merge all new builds into existing flatpak repo
for export_repo in "$@"; do
  mkdir -p "$export_repo/refs/remotes" "$export_repo/refs/mirrors"

  ostree refs --repo="$export_repo" | while IFS= read -r ref; do
    echo "merge_flatpak_repo: $export_repo -> $repo: $ref"
    ostree pull-local --repo="$repo" "$export_repo" "$ref"
  done
done

flatpak build-update-repo --gpg-sign="$GPG_KEY_ID" "$repo"
