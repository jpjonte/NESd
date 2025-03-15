#!/usr/bin/env bash

# exit on error, treat unset variables as errors, and fail if a pipeline fails
set -euo pipefail

cd "$(dirname "$0")/.."

rm -f .git/hooks/pre-commit
