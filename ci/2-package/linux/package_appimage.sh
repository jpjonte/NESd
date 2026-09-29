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
sudo apt-get install -y locate zsync

wget -O appimagetool "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$full_arch.AppImage"
chmod +x appimagetool
mv appimagetool /usr/local/bin/

export APPIMAGE_EXTRACT_AND_RUN=1

bundle="$app_root/build/linux/$ARCH/$FLAVOR/release/bundle"
packaging="$app_root/linux/packaging"

mkdir -p nesd.AppDir/usr/lib

cp -r "$bundle"/* nesd.AppDir

id=$(bash "$packaging/render.sh" "$FLAVOR" nesd nesd.AppDir/usr/share)

case "$FLAVOR" in
  prod)
    logo="logo.png"
    release="latest"
    ;;
  dev)
    logo="logo-dev.png"
    release="nightly"
    ;;
esac

update_info="gh-releases-zsync|jpjonte|NESd|$release|${ARTIFACT_FLAVORED%%.*}.*.$full_arch.AppImage.zsync"

# copy desktop entry to AppDir root for appimagetool
cp "nesd.AppDir/usr/share/applications/$id.desktop" nesd.AppDir/
# copy PNG image for AppImage catalog https://github.com/AppImage/appimage.github.io
cp "$app_root/assets/$logo" "nesd.AppDir/$id.png"

cp "$packaging/appimage/AppRun" nesd.AppDir/AppRun

chmod +x nesd.AppDir/AppRun

appimagetool --no-appstream --updateinformation "$update_info" \
  nesd.AppDir "$ARTIFACT_FLAVORED.$full_arch.AppImage"
