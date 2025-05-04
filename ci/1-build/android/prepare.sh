#!/usr/bin/env bash

set -eux

echo "$KEY_STORE_BASE64" | base64 --decode > /tmp/upload-keystore.jks

echo "$KEY_PROPERTIES" > android/key.properties
