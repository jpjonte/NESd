#!/usr/bin/env bash

if [[ "$ARCH" == "arm64" ]]; then
  full_arch="aarch64"
else
  full_arch="x86_64"
fi

flatpak build-bundle \
  --arch="$full_arch" \
  --gpg-sign="$GPG_KEY_ID" \
  repo \
  dev.jpj.NESd.flatpak \
  dev.jpj.NESd
