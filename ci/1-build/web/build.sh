#!/usr/bin/env bash

set -eux

repo_root=$(git rev-parse --show-toplevel)

pushd "$repo_root/packages/nesd" >/dev/null

flutter build web --wasm --release --no-web-resources-cdn

popd >/dev/null
