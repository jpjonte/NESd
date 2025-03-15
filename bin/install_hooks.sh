#!/usr/bin/env bash

# exit on error, treat unset variables as errors, and fail if a pipeline fails
set -euo pipefail

cd "$(dirname "$0")/.."

ln -sf ../../bin/pre-commit.sh .git/hooks/pre-commit
