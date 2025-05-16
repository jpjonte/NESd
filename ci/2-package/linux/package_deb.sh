#!/usr/bin/env bash

mkdir -p deb/DEBIAN \
  deb/usr/share/{dev.jpj.NESd,applications,metainfo} \
  deb/usr/share/icons/hicolor/scalable/apps

cp assets/logo.svg deb/usr/share/icons/hicolor/scalable/apps/dev.jpj.NESd.svg

cp linux/packaging/dev.jpj.NESd.metainfo.xml deb/usr/share/metainfo/

cp -r build/linux/"$ARCH"/release/bundle/* deb/usr/share/dev.jpj.NESd/

cp linux/packaging/deb/control-"$ARCH" deb/DEBIAN/control
cp linux/packaging/deb/postinst deb/DEBIAN/postinst
cp linux/packaging/deb/postrm deb/DEBIAN/postrm

cp linux/packaging/dev.jpj.NESd.desktop deb/usr/share/applications/

chmod +x deb/DEBIAN/postinst deb/DEBIAN/postrm

dpkg-deb --build --root-owner-group deb nesd.deb
