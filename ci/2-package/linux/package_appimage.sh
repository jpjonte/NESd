#!/usr/bin/env bash

set -eux

if [[ "$ARCH" == "arm64" ]]; then
  full_arch="aarch64"
else
  full_arch="x86_64"
fi

repo_root=$(git rev-parse --show-toplevel)
app_root="$repo_root/packages/nesd"

sudo apt-get update -y
sudo apt-get install -y locate

wget -O appimagetool "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$full_arch.AppImage"
chmod +x appimagetool
mv appimagetool /usr/local/bin/

export APPIMAGE_EXTRACT_AND_RUN=1

bundle="$app_root/build/linux/$ARCH/$FLAVOR/release/bundle"
packaging="$app_root/linux/packaging"

mkdir -p nesd.AppDir/usr/lib

cp -r "$bundle"/* nesd.AppDir

id=$(bash "$packaging/render.sh" "$FLAVOR" nesd nesd.AppDir/usr/share)

# appimagetool wants the desktop entry and its icon at the AppDir root.
cp "nesd.AppDir/usr/share/applications/$id.desktop" nesd.AppDir/
cp "nesd.AppDir/usr/share/icons/hicolor/scalable/apps/$id.svg" nesd.AppDir/

cp "$packaging/appimage/AppRun" nesd.AppDir/AppRun

chmod +x nesd.AppDir/AppRun

appimagetool --no-appstream nesd.AppDir "$ARTIFACT_FLAVORED".linux-"$ARCH".AppImage
