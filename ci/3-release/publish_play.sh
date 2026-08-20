#!/usr/bin/env bash
# Upload the pre-built AAB to Google Play.
set -eux

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)

bundle_dir="$repo_root/packages/nesd/build/app/outputs/bundle/prodRelease"

notes_dir="$repo_root/packages/nesd/android/app/src/main/play/release-notes/en-US"

mkdir -p "$notes_dir"

"$repo_root/ci/3-release/play_release_notes.sh" "$repo_root/CHANGELOG.md" \
  > "$notes_dir/default.txt"

pushd "$repo_root/packages/nesd/android" >/dev/null

./gradlew publishProdReleaseBundle --artifact-dir "$bundle_dir" \
  publishProdReleaseListing \
  --no-daemon \
  -PplayTrack="${PLAY_TRACK:-internal}"

popd >/dev/null
