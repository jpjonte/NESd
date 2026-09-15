#!/usr/bin/env bash
set -euo pipefail

shards=$1

cd "$(dirname "$0")/../.."

args=()

if lcov --version | grep -qE 'version 2'; then
  args+=(--ignore-errors empty)
fi

for file in "$shards"/*/lcov.info; do
  args+=(-a "$file")
done

mkdir -p packages/nesd/coverage
lcov "${args[@]}" -o packages/nesd/coverage/lcov.info
