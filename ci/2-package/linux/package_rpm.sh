#!/usr/bin/env bash

set -eu

mkdir -p rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

cp -r build/linux/"$ARCH"/release/bundle rpmbuild/BUILD/nesd

patchelf --set-rpath '$ORIGIN' rpmbuild/BUILD/nesd/lib/liburl_launcher_linux_plugin.so
patchelf --set-rpath '$ORIGIN' rpmbuild/BUILD/nesd/lib/libgamepads_linux_plugin.so

cp assets/logo.svg rpmbuild/BUILD/dev.jpj.NESd.svg

cp linux/packaging/dev.jpj.NESd.metainfo.xml rpmbuild/BUILD/nesd.metainfo.xml
cp linux/packaging/dev.jpj.NESd.desktop rpmbuild/BUILD/nesd.desktop

cp linux/packaging/rpm/nesd.spec rpmbuild/SPECS/

rpmbuild \
  --buildroot "$(pwd)/rpmbuild/BUILDROOT" \
  --define '_topdir rpmbuild' \
  --define "arch_ $FULL_ARCH" \
  --define 'source_date_epoch_from_changelog 0' \
  -bb rpmbuild/SPECS/nesd.spec

mv rpmbuild/RPMS/**/*.rpm ./"$ARTIFACT".linux-"$ARCH".rpm
