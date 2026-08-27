#!/usr/bin/env bash

set -eux

repo_root=$(git rev-parse --show-toplevel)

build_id=$("$repo_root/ci/build_id.sh")

pushd "$repo_root/packages/nesd" >/dev/null

flutter build web --wasm --release --no-web-resources-cdn \
  --dart-define=NESD_BUILD_ID="$build_id"

popd >/dev/null
