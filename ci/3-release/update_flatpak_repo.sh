#!/usr/bin/env bash
set -eu

flatpak build-update-repo --gpg-sign="$GPG_KEY_ID" "$1"
