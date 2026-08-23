#!/usr/bin/env bash

set -eux

repo_root=$(git rev-parse --show-toplevel)
app_root="$repo_root/packages/nesd"
packaging="$app_root/linux/packaging"
bundle="$app_root/build/linux/$ARCH/$FLAVOR/release/bundle"

bin="$FLAVORED_ID"

if [[ "$ARCH" == "arm64" ]]; then
  deb_arch="arm64"
else
  deb_arch="amd64"
fi

package=$(bash "$packaging/render.sh" "$FLAVOR" "$bin" deb/usr/share)

mkdir -p deb/DEBIAN "deb/usr/share/$package"
cp -r "$bundle"/* "deb/usr/share/$package/"

size=$(du -sk deb/usr | cut -f1)

bash "$packaging/template.sh" "$packaging/deb/control.in" deb/DEBIAN/control \
  "PACKAGE=$package" "VERSION=$VERSION" "ARCH=$deb_arch" "SIZE=$size"
bash "$packaging/template.sh" "$packaging/deb/postinst.in" deb/DEBIAN/postinst \
  "PACKAGE=$package" "BIN=$bin"
bash "$packaging/template.sh" "$packaging/deb/postrm.in" deb/DEBIAN/postrm \
  "BIN=$bin"

chmod +x deb/DEBIAN/postinst deb/DEBIAN/postrm

dpkg-deb --build --root-owner-group deb "$ARTIFACT_FLAVORED".linux-"$ARCH".deb
