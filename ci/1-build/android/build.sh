#!/usr/bin/env bash

set -eux

if [ "$FLAVOR" = "prod" ]; then
  flutter build apk --release --flavor prod
elif [ "$FLAVOR" = "dev" ]; then
  flutter build apk --release --flavor dev
fi

rm /tmp/upload-keystore.jks
rm android/key.properties

mv build/app/outputs/flutter-apk/*.apk ./"$ARTIFACT_FLAVORED".android.apk
