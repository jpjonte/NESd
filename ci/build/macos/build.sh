#!/usr/bin/env bash

set -eux

flutter build macos --release --flavor "$FLAVOR"

dmgbuild -s ci/build/macos/dmg-settings.py "$FLAVORED_NAME" "$MACOS_ARTIFACT"
