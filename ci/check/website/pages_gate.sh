#!/usr/bin/env bash
# Exercise website/tool/pages_gate.sh against fixed inputs, so a broken gate
# fails a PR instead of silently skipping (or double-deploying) the website.
set -euo pipefail

root=$(git rev-parse --show-toplevel)
gate="$root/website/tool/pages_gate.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fail() { echo "pages_gate check: $*" >&2; exit 1; }

assert_deploy() {
  local want="$1" version="$2" latest="$3" got
  printf 'name: nesd\nversion: %s\n' "$version" > "$tmp/pubspec.yaml"

  got=$(bash "$gate" "$tmp/pubspec.yaml" "$latest" | sed -n 's/^deploy=//p')

  [ "$got" = "$want" ] || \
    fail "version=$version latest=$latest: want deploy=$want, got '$got'"
}

# A normal push: the pubspec still names the latest release.
assert_deploy true 0.17.0 0.17.0

# The release commit: the pubspec was bumped but the tag run has not
# published the release yet, so the tag run must do the deploy.
assert_deploy false 0.17.0 0.16.0

# A build number on the pubspec version does not change the comparison.
assert_deploy true 0.17.0+3 0.17.0

# The result is also exported as a step output when GITHUB_OUTPUT is set.
printf 'version: 0.17.0\n' > "$tmp/pubspec.yaml"
: > "$tmp/output"
GITHUB_OUTPUT="$tmp/output" bash "$gate" "$tmp/pubspec.yaml" 0.16.0 >/dev/null
grep -qx 'deploy=false' "$tmp/output" || fail "deploy=false missing from GITHUB_OUTPUT"

# A pubspec without a version is an error, not a deploy.
printf 'name: nesd\n' > "$tmp/pubspec.yaml"

if bash "$gate" "$tmp/pubspec.yaml" 0.17.0 >/dev/null 2>&1; then
  fail "expected failure for a pubspec without a version"
fi

echo "pages_gate check: ok"
