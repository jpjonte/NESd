#!/usr/bin/env bash

set -eux

repo_root=$(git rev-parse --show-toplevel)

pushd "$repo_root/packages/nesd" >/dev/null

flutter build macos --release --flavor "$FLAVOR"

popd >/dev/null

dmgbuild -s "$repo_root"/ci/1-build/macos/dmg-settings.py "$FLAVORED_NAME" "$ARTIFACT_FLAVORED".macos-universal.dmg
