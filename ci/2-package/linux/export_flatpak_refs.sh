#!/usr/bin/env bash
set -eu

if [[ "$ARCH" == "arm64" ]]; then
  full_arch="aarch64"
else
  full_arch="x86_64"
fi

ostree init --repo=flatpak-export --mode=archive-z2

# export current build into separate repo,
# so all builds can be merged into the real repo together
for ref in "app/$FLATPAK_ID/$full_arch/master" \
  "runtime/$FLATPAK_ID.Debug/$full_arch/master"; do
  echo "export_flatpak_refs: $ref"
  ostree pull-local --repo=flatpak-export repo "$ref"
done
