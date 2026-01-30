#!/usr/bin/env bash

set -eux

arch=${1:-}

if [[ "$arch" == "arm64" ]]; then
  full_arch="aarch64"
else
  full_arch="x86_64"
fi

flutter_version=$(jq -r '.flutter' .fvmrc)

version=$(yq '.version' packages/nesd/pubspec.yaml)

flavor="dev"
flavored_id="nesd-dev"
flavored_name="NESd dev"

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

artifact="nesd.$release_name"
artifact_flavored="$flavored_id.$release_name"

{
  echo "flutter_version=$flutter_version"
  echo "version=$version"
  echo "flavored_name=$flavored_name"
  echo "release_name=$release_name"
  echo "artifact=$artifact"
  echo "artifact_flavored=$artifact_flavored"
} >> "$GITHUB_OUTPUT"

{
  echo "ARCH=$arch"
  echo "FLUTTER_VERSION=$flutter_version"
  echo "FULL_ARCH=$full_arch"
  echo "VERSION=$version"
  echo "RELEASE_NAME=$release_name"
  echo "ARTIFACT=$artifact"
  echo "ARTIFACT_FLAVORED=$artifact_flavored"
  echo "FLAVOR=$flavor"
  echo "FLAVORED_ID=$flavored_id"
  echo "FLAVORED_NAME=\"$flavored_name\""
} >> "$GITHUB_ENV"
