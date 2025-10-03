#!/usr/bin/env bash

set -eux

repo_root=$(git rev-parse --show-toplevel)

pushd "$repo_root/packages/nesd" >/dev/null
flutter pub get
popd >/dev/null

find ~/.pub-cache/git -maxdepth 1 -type d -name 'mp-audio-stream*' -exec bash -c "cd {}; git submodule init && git submodule update" \;
