#!/usr/bin/env bash
# Upload the pre-built AAB to Google Play.
set -eux

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)

bundle_dir="$repo_root/packages/nesd/build/app/outputs/bundle/prodRelease"

pushd "$repo_root/packages/nesd/android" >/dev/null

./gradlew publishProdReleaseBundle --artifact-dir "$bundle_dir" \
  publishProdReleaseListing \
  --no-daemon \
  -PplayTrack="${PLAY_TRACK:-internal}"

popd >/dev/null
