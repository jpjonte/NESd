#!/usr/bin/env bash

set -eux

version=$(yq '.version' pubspec.yaml)

flavor="dev"

if [ "$GITHUB_REF_TYPE" == "tag" ]; then
  release_name="$version"
  flavor="prod"
elif [ "$GITHUB_REF_NAME" == "main" ]; then
  release_name="nightly"
else
  release_name=$(git rev-parse --short HEAD)
fi

{
  echo "version=$version"
  echo "dist_path=dist/$version"
  echo "macos_artifact=nesd.$release_name.macos-universal.dmg"
  echo "linux_deb_artifact=nesd.$release_name.linux-x64.deb"
  echo "linux_rpm_artifact=nesd.$release_name.linux-x64.rpm"
  echo "windows_path=build/windows/x64/runner/Release"
  echo "windows_artifact=nesd.$release_name.windows-x64.zip"
  echo "android_path=build/app/outputs/flutter-apk/app-$flavor-release.apk"
  echo "android_artifact=nesd.$release_name.android.apk"
  echo "release_name=$release_name"
  echo "flavor=$flavor"
} >> "$GITHUB_OUTPUT"
