#!/usr/bin/env bash

set -eux

repo_root=$(git rev-parse --show-toplevel)
app_root="$repo_root/packages/nesd"

mkdir -p deb/DEBIAN \
  deb/usr/share/{dev.jpj.NESd,applications,metainfo} \
  deb/usr/share/icons/hicolor/scalable/apps

cp "$app_root/assets/logo.svg" \
  deb/usr/share/icons/hicolor/scalable/apps/dev.jpj.NESd.svg

cp "$app_root/linux/packaging/dev.jpj.NESd.metainfo.xml" \
  deb/usr/share/metainfo/

cp -r "$app_root/build/linux/$ARCH/release/bundle"/* \
  deb/usr/share/dev.jpj.NESd/

cp "$app_root/linux/packaging/deb/control-$ARCH" deb/DEBIAN/control
cp "$app_root/linux/packaging/deb/postinst" deb/DEBIAN/postinst
cp "$app_root/linux/packaging/deb/postrm" deb/DEBIAN/postrm

cp "$app_root/linux/packaging/dev.jpj.NESd.desktop" \
  deb/usr/share/applications/

chmod +x deb/DEBIAN/postinst deb/DEBIAN/postrm

dpkg-deb --build --root-owner-group deb nesd.deb
