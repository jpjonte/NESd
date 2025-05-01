#!/usr/bin/env bash

set -eux

flavor=dev

if [ "$GITHUB_REF_TYPE" == "tag" ]; then
  flavor="prod"
fi

mkdir -p build/linux/x64/release/bundle/
cp linux/eslz4-linux64.so build/linux/x64/release/bundle/

fastforge release --name $flavor-linux --skip-clean
