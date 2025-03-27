#!/usr/bin/env bash

set -eu

gpg_private_key="${FLATPAK_NIGHTLY_GPG_PRIVATE_KEY:-}"
gpg_passphrase="${FLATPAK_NIGHTLY_GPG_PASSPHRASE:-}"

if [ "$GITHUB_REF_TYPE" == "tag" ]; then
  gpg_private_key="${FLATPAK_STABLE_GPG_PRIVATE_KEY:-}"
  gpg_passphrase="${FLATPAK_STABLE_GPG_PASSPHRASE:-}"
fi

{
  echo "gpg_private_key<<EOF"
  echo "$gpg_private_key"
  echo "EOF"
  echo "gpg_passphrase=$gpg_passphrase"
} >> "$GITHUB_OUTPUT"
