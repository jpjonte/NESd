#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

# CI moves the rolling `nightly` tag to `main` on every build. Git refuses to
# move an existing tag unless the refspec is forced, so fetches fail with
# "would clobber existing tag" until the local tag is deleted by hand.

remote="${1:-$(git config --get branch.main.remote || echo origin)}"
refspec="+refs/tags/nightly:refs/tags/nightly"

if git config --get-all "remote.$remote.fetch" | grep -qxF "$refspec"; then
  echo "remote '$remote' already forces the nightly tag"
  exit 0
fi

git config --add "remote.$remote.fetch" "$refspec"

echo "remote '$remote' now force-updates the nightly tag on fetch"
