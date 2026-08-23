#!/usr/bin/env bash

set -eu

if [[ "$ARCH" == "arm64" ]]; then
  full_arch="aarch64"
else
  full_arch="x86_64"
fi

repo_root=$(git rev-parse --show-toplevel)
app_root="$repo_root/packages/nesd"
packaging="$app_root/linux/packaging"
bundle="$app_root/build/linux/$ARCH/$FLAVOR/release/bundle"

name="$FLAVORED_ID"

mkdir -p rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

cp -r "$bundle" rpmbuild/BUILD/bundle

patchelf --set-rpath '$ORIGIN' rpmbuild/BUILD/bundle/lib/liburl_launcher_linux_plugin.so
patchelf --set-rpath '$ORIGIN' rpmbuild/BUILD/bundle/lib/libgamepads_linux_plugin.so

bash "$packaging/render.sh" "$FLAVOR" "$name" rpmbuild/BUILD/share

cp "$packaging/rpm/nesd.spec" rpmbuild/SPECS/

rpmbuild \
  --buildroot "$(pwd)/rpmbuild/BUILDROOT" \
  --define '_topdir rpmbuild' \
  --define "arch_ $full_arch" \
  --define "name_ $name" \
  --define "version_ $VERSION" \
  --define 'source_date_epoch_from_changelog 0' \
  -bb rpmbuild/SPECS/nesd.spec

mv rpmbuild/RPMS/**/*.rpm ./"$ARTIFACT_FLAVORED".linux-"$ARCH".rpm
