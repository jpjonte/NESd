#!/usr/bin/env bash

# exit on error, treat unset variables as errors, and fail if a pipeline fails
set -euo pipefail

flutter analyze lib test
