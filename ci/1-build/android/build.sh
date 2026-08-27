#!/usr/bin/env bash

set -eux

repo_root=$(git rev-parse --show-toplevel)

version_args=(--dart-define=NESD_BUILD_ID="${NESD_BUILD_ID:-}")

if [ "${GITHUB_REF_TYPE:-}" = "tag" ]; then
  if [ "${GITHUB_REF_NAME:-}" != "$VERSION" ]; then
    echo "build.sh: tag '${GITHUB_REF_NAME:-}' does not match" \
         "pubspec version '$VERSION'" >&2
    exit 1
  fi

  version_code=$("$repo_root/ci/1-build/android/version_code.sh" "$VERSION")

  version_args+=(--build-number="$version_code" --build-name="$VERSION")
fi

pushd "$repo_root/packages/nesd" >/dev/null

if [ "$FLAVOR" = "prod" ]; then
  flutter build apk --release --flavor prod "${version_args[@]+"${version_args[@]}"}"
elif [ "$FLAVOR" = "dev" ]; then
  flutter build apk --release --flavor dev "${version_args[@]+"${version_args[@]}"}"
fi

# build appbundle for Play Store submission
if [ "$FLAVOR" = "prod" ] && [ "${GITHUB_REF_TYPE:-}" = "tag" ]; then
  flutter build appbundle --release --flavor prod "${version_args[@]+"${version_args[@]}"}"
fi

rm /tmp/upload-keystore.jks
rm android/key.properties

mv build/app/outputs/flutter-apk/*.apk "$repo_root/${ARTIFACT_FLAVORED}.android.apk"

popd >/dev/null
