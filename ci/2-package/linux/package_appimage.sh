#!/usr/bin/env bash

set -eux

repo_root=$(git rev-parse --show-toplevel)
app_root="$repo_root/packages/nesd"

sudo apt-get update -y
sudo apt-get install -y locate

wget -O appimagetool "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$FULL_ARCH.AppImage"
chmod +x appimagetool
mv appimagetool /usr/local/bin/

mkdir -p nesd.AppDir/{usr/share/icons/hicolor/scalable/apps,usr/share/metainfo,usr/lib}

cp -r "$app_root/build/linux/$ARCH/release/bundle"/* nesd.AppDir

cp "$app_root/linux/packaging/dev.jpj.NESd.desktop" nesd.AppDir/nesd.desktop
cp "$app_root/linux/packaging/dev.jpj.NESd.metainfo.xml" \
  nesd.AppDir/usr/share/metainfo/nesd.metainfo.xml

cp "$app_root/linux/packaging/appimage/AppRun" nesd.AppDir/AppRun

cp "$app_root/assets/logo.svg" nesd.AppDir/dev.jpj.NESd.svg
cp "$app_root/assets/logo.svg" \
  nesd.AppDir/usr/share/icons/hicolor/scalable/apps/dev.jpj.NESd.svg

chmod +x nesd.AppDir/AppRun

appimagetool --no-appstream nesd.AppDir "$ARTIFACT".AppImage

mv ./*.AppImage "$ARTIFACT".linux-"$ARCH".AppImage
