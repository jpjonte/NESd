#!/usr/bin/env bash
set -euo pipefail

index="${1:?usage: inject_visit_script.sh <index.html>}"
tag='<script defer src="/js/visit.js"></script>'

if grep -qF "$tag" "$index"; then
  echo "inject_visit_script: $index already carries the counter" >&2
  exit 1
fi

heads=$(grep -c '</head>' "$index" || true)

if [ "$heads" != 1 ]; then
  echo "inject_visit_script: expected one </head> in $index, found $heads" >&2
  exit 1
fi

# awk rather than sed -i: the in-place flag differs between GNU and BSD sed.
tmp=$(mktemp)
awk -v tag="$tag" '
  /<\/head>/ { sub(/<\/head>/, "  " tag "\n</head>") }
  { print }
' "$index" > "$tmp"
mv "$tmp" "$index"

echo "inject_visit_script: added the counter to $index"
