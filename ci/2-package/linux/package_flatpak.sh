#!/usr/bin/env bash

flatpak build-bundle \
  --arch="$FULL_ARCH" \
  --gpg-sign="$GPG_KEY_ID" \
  repo \
  dev.jpj.NESd.flatpak \
  dev.jpj.NESd
