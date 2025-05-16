#!/usr/bin/env bash

set -eux

flutter build macos --release --flavor "$FLAVOR"

dmgbuild -s ci/1-build/macos/dmg-settings.py "$FLAVORED_NAME" "$ARTIFACT_FLAVORED".macos-universal.dmg
