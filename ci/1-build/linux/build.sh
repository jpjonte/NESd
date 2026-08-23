#!/usr/bin/env bash

set -eux

repo_root=$(git rev-parse --show-toplevel)

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y --no-install-recommends \
  binutils \
  clang \
  cmake \
  libgtk-3-dev \
  ninja-build \
  pkg-config

pushd "$repo_root/packages/nesd" >/dev/null

mkdir -p build/linux/"$ARCH"/"$FLAVOR"/release/bundle/

flutter build linux --release --flavor "$FLAVOR" --target-platform=linux-"$ARCH"

popd >/dev/null
