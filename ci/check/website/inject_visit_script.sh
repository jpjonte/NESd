#!/usr/bin/env bash
set -euo pipefail

root=$(git rev-parse --show-toplevel)
inject="$root/website/tool/inject_visit_script.sh"
tag='<script defer src="/js/visit.js"></script>'
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fail() { echo "inject_visit_script check: $*" >&2; exit 1; }

[ -f "$inject" ] || fail "$inject missing"

printf '<html>\n<head>\n<title>x</title>\n</head>\n<body></body>\n</html>\n' \
  > "$tmp/index.html"
bash "$inject" "$tmp/index.html"

[ "$(grep -cF "$tag" "$tmp/index.html")" = 1 ] || fail "tag not added exactly once"
grep -A1 -F "$tag" "$tmp/index.html" | grep -q '</head>' \
  || fail "tag not placed right before </head>"

if bash "$inject" "$tmp/index.html" 2>/dev/null; then
  fail "expected refusal on a second run"
fi

[ "$(grep -cF "$tag" "$tmp/index.html")" = 1 ] || fail "second run changed the file"

printf '<html><body></body></html>\n' > "$tmp/nohead.html"

if bash "$inject" "$tmp/nohead.html" 2>/dev/null; then
  fail "expected failure without </head>"
fi

cp "$root/packages/nesd/web/index.html" "$tmp/play.html"
bash "$inject" "$tmp/play.html"
[ "$(grep -cF "$tag" "$tmp/play.html")" = 1 ] || fail "real index.html not handled"

printf '<html><head><title>x</title></head><body></body></html>\n' \
  > "$tmp/oneline.html"
bash "$inject" "$tmp/oneline.html"
grep -q "$tag"'$' "$tmp/oneline.html" || fail "tag not inserted before </head> on a one-line head"
grep -qx '</head><body></body></html>' "$tmp/oneline.html" \
  || fail "one-line head not split after the tag"

echo "inject_visit_script check: ok"
