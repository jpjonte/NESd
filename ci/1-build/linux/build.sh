#!/usr/bin/env bash

set -eux

sudo apt-get update -y
sudo apt-get install -y ninja-build libgtk-3-dev

mkdir -p build/linux/"$ARCH"/release/bundle/

flutter build linux --release --target-platform=linux-"$ARCH"
