#!/usr/bin/env bash

set -eux

repo_root=$(git rev-parse --show-toplevel)
app_root="$repo_root/packages/nesd"

echo "$KEY_STORE_BASE64" | base64 --decode > /tmp/upload-keystore.jks

echo "$KEY_PROPERTIES" > "$app_root/android/key.properties"

set +x
if [ -n "${PLAY_SERVICE_ACCOUNT_JSON_BASE64:-}" ]; then
  printf '%s' "$PLAY_SERVICE_ACCOUNT_JSON_BASE64" \
    | tr -d ' \t\n\r' \
    | base64 --decode > "$app_root/android/play-service-account.json"
fi
set -x
