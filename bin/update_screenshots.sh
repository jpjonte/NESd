#!/usr/bin/env bash
# Regenerate the Play listing screenshots inside the same Linux container
# CI uses.
#
# Usage (from anywhere in the repo):
#   bin/update_screenshots.sh                    # every screenshot
#   bin/update_screenshots.sh --plain-name 04_   # a subset

set -eu

IMAGE='ghcr.io/jpjonte/flutter:stable-ci'

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

exec docker run --rm \
  -v "$repo_root:/workspace" \
  -v /workspace/.dart_tool \
  -v /workspace/packages/nesd/.dart_tool \
  -v /workspace/packages/nesd_audio/build \
  -w /workspace \
  "$IMAGE" \
  sh -c 'flutter pub get >/dev/null && cd packages/nesd && \
         exec flutter test test/screenshots --run-skipped "$@"' \
  sh "$@"
