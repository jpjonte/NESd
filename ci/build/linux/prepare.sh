#!/usr/bin/env bash

set -eux

sudo apt-get update -y
sudo apt-get install -y ninja-build libgtk-3-dev rpm patchelf

dart pub global activate fastforge
