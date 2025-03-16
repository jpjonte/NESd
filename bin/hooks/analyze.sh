#!/usr/bin/env bash

# exit on error, treat unset variables as errors, and fail if a pipeline fails
set -euo pipefail

git diff --cached --name-only --diff-filter=ACMR -z | \
    xargs -0 flutter analyze
