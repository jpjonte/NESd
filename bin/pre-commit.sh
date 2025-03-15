#!/usr/bin/env bash

echo "Running pre-commit hook"

# exit on error, treat unset variables as errors, and fail if a pipeline fails
set -euo pipefail

bin/hooks/analyze.sh
