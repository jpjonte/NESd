#!/usr/bin/env bash

set -eux

version=$(yq '.version' pubspec.yaml)

flavor="dev"
flavored_id="nesd-$flavor"
flavored_name="NESd $flavor"

if [ "$GITHUB_REF_TYPE" == "tag" ]; then
  release_name="$version"
  flavor="prod"
  flavored_id="nesd"
  flavored_name="NESd"
elif [ "$GITHUB_REF_NAME" == "main" ]; then
  release_name="nightly"
else
  release_name=$(git rev-parse --short HEAD)
fi

macos_artifact=$flavored_id.$release_name.macos-universal.dmg

{
  echo "version=$version"
  echo "dist_path=dist/$version"
  echo "macos_artifact=$macos_artifact"
  echo "linux_deb_artifact=nesd.$release_name.linux-x64.deb"
  echo "linux_rpm_artifact=nesd.$release_name.linux-x64.rpm"
  echo "windows_artifact=nesd.$release_name.windows-x64.zip"
  echo "android_path=build/app/outputs/flutter-apk/app-$flavor-release.apk"
  echo "android_artifact=nesd.$release_name.android.apk"
  echo "release_name=$release_name"
} >> "$GITHUB_OUTPUT"

{
  echo "FLAVOR=$flavor"
  echo "FLAVORED_ID=$flavored_id"
  echo "FLAVORED_NAME=\"$flavored_name\""
  echo "MACOS_ARTIFACT=$macos_artifact"
} >> "$GITHUB_ENV"
