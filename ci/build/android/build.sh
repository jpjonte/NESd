#!/usr/bin/env bash

set -eux

flutter build apk --release

rm /tmp/upload-keystore.jks
rm android/key.properties
