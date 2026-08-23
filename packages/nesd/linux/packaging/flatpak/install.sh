#!/usr/bin/env bash
set -euo pipefail

case "$FLATPAK_ARCH" in
  x86_64) arch=x64 ;;
  aarch64) arch=arm64 ;;
  *)
    echo "install.sh: unsupported arch $FLATPAK_ARCH" >&2
    exit 1
    ;;
esac

case "$FLATPAK_ID" in
  dev.jpj.NESd) flavor=prod ;;
  dev.jpj.NESd.dev) flavor=dev ;;
  *)
    echo "install.sh: unknown app id $FLATPAK_ID" >&2
    exit 1
    ;;
esac

cp -r "build/linux/$arch/$flavor/release/bundle"/* "$FLATPAK_DEST"
chmod +x "$FLATPAK_DEST/nesd"
mkdir -p "$FLATPAK_DEST/bin"
ln -s /app/nesd "$FLATPAK_DEST/bin/nesd"

id=$(bash linux/packaging/render.sh "$flavor" nesd "$FLATPAK_DEST/share")

if [ "$id" != "$FLATPAK_ID" ]; then
  echo "install.sh: rendered $id for $flavor but building $FLATPAK_ID" >&2
  exit 1
fi
