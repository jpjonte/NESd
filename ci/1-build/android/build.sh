#!/usr/bin/env bash

set -eux

repo_root=$(git rev-parse --show-toplevel)

pushd "$repo_root/packages/nesd" >/dev/null

if [ "$FLAVOR" = "prod" ]; then
  flutter build apk --release --flavor prod
elif [ "$FLAVOR" = "dev" ]; then
  flutter build apk --release --flavor dev
fi

rm /tmp/upload-keystore.jks
rm android/key.properties

mv build/app/outputs/flutter-apk/*.apk "$repo_root/${ARTIFACT_FLAVORED}.android.apk"

popd >/dev/null
