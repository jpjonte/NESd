#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

out="${1:-build/site}"
src="build/jaspr"

# clean target directory unless it was overridden
if [ $# -eq 0 ]; then
  rm -rf "$out"
fi

for page in index.html privacy/index.html; do
  if [ ! -f "$src/$page" ]; then
    echo "stage: $src/$page missing. Run 'dart run jaspr_cli:jaspr build' first" >&2
    exit 1
  fi
done

mkdir -p "$out"

rsync -a \
  --exclude 'packages/' \
  --exclude '.dart_tool/' \
  --exclude '.build.manifest' \
  "$src/" "$out/"

rm -rf "$src/packages"

echo "stage: $(find "$out" -type f | wc -l | tr -d ' ') files -> $out"
