#!/usr/bin/env bash

set -eux

repo_root=$(git rev-parse --show-toplevel)

sudo apt-get update -y
sudo apt-get install -y ninja-build libgtk-3-dev

pushd "$repo_root/packages/nesd" >/dev/null

mkdir -p build/linux/"$ARCH"/release/bundle/

flutter build linux --release --target-platform=linux-"$ARCH"

popd >/dev/null
