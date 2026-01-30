#!/usr/bin/env bash

set -eux

repo_root=$(git rev-parse --show-toplevel)
app_root="$repo_root/packages/nesd"

echo "$KEY_STORE_BASE64" | base64 --decode > /tmp/upload-keystore.jks

echo "$KEY_PROPERTIES" > "$app_root/android/key.properties"
