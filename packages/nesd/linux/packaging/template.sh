#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "usage: template.sh IN OUT KEY=VALUE..." >&2
  exit 2
fi

in=$1
out=$2
shift 2

args=()

for pair in "$@"; do
  key=${pair%%=*}
  value=${pair#*=}
  args+=(-e "s|@$key@|$value|g")
done

mkdir -p "$(dirname "$out")"

if [ ${#args[@]} -eq 0 ]; then
  cp "$in" "$out"
else
  sed "${args[@]}" "$in" > "$out"
fi

if grep -Eq '@[A-Z_]+@' "$out"; then
  echo "template.sh: unsubstituted token in $in:" >&2
  grep -Eo '@[A-Z_]+@' "$out" | sort -u >&2
  rm -f "$out"
  exit 1
fi
