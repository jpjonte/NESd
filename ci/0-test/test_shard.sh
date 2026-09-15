#!/usr/bin/env bash
set -euo pipefail

index=$1
count=$2

cd "$(git rev-parse --show-toplevel)/packages/nesd"

files=$(find test -name '*_test.dart' | sort | awk -v n="$count" -v i="$index" 'NR % n == i')

echo "shard $index/$count: $(echo "$files" | wc -l) files"

# shellcheck disable=SC2086
flutter test --coverage --concurrency 4 $files
