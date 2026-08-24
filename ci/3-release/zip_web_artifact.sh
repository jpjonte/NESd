#!/usr/bin/env sh

set -eu

mv web-build artifacts/"$ARTIFACT".web

cd artifacts

zip -qr "$ARTIFACT".web.zip "$ARTIFACT".web

rm -rf "$ARTIFACT".web
