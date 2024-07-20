#!/usr/bin/env bash

set -eux

version=$(yq '.version' pubspec.yaml)

if [ "$GITHUB_REF_TYPE" == "tag" ]; then
  release_name="$version"
elif [ "$GITHUB_REF_NAME" == "main" ]; then
  release_name="latest"
else
  release_name="$GITHUB_SHA"
fi

{
  echo "version=$version"
  echo "path=dist/$version/nesd-$version+$version-macos.dmg"
  echo "release_name=$release_name"
} >> "$GITHUB_OUTPUT"
