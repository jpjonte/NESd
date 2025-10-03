#!/usr/bin/env bash

# exit on error, treat unset variables as errors, and fail if a pipeline fails
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)

pushd "$repo_root/packages/nesd" >/dev/null
flutter analyze
popd >/dev/null
