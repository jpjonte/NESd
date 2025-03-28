#!/usr/bin/env bash

set -eux

flavor=dev

if [ "$GITHUB_REF_TYPE" == "tag" ]; then
  flavor="prod"
fi

fastforge release --name $flavor-macos --skip-clean
