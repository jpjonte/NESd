#!/usr/bin/env bash
set -eu

if [[ "$ARCH" == "arm64" ]]; then
  full_arch="aarch64"
else
  full_arch="x86_64"
fi

old="app/dev.jpj.NESd/$full_arch/master"

if ! ostree refs --repo=repo | grep -qx "$old"; then
  echo "retire_flatpak_ref: $old not present, nothing to do"
  exit 0
fi

if ostree show --repo=repo --print-metadata-key=ostree.endoflife-rebase "$old" >/dev/null 2>&1; then
  echo "retire_flatpak_ref: $old already end-of-lifed"
  exit 0
fi

# build-commit-from insists on a source; --src-ref alone means "from the
# same repo", and an end-of-life option always produces a new commit.
flatpak build-commit-from \
  --src-ref="$old" \
  --end-of-life-rebase=dev.jpj.NESd=dev.jpj.NESd.dev \
  --gpg-sign="$GPG_KEY_ID" \
  repo "$old"
