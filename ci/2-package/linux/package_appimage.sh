#!/usr/bin/env bash

sudo apt-get update -y
sudo apt-get install -y locate

wget -O appimagetool "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$FULL_ARCH.AppImage"
chmod +x appimagetool
mv appimagetool /usr/local/bin/

mkdir -p nesd.AppDir/{usr/share/icons/hicolor/scalable/apps,usr/share/metainfo,usr/lib}

cp -r build/linux/"$ARCH"/release/bundle/* nesd.AppDir

cp linux/packaging/dev.jpj.NESd.desktop nesd.AppDir/nesd.desktop
cp linux/packaging/dev.jpj.NESd.metainfo.xml nesd.AppDir/usr/share/metainfo/nesd.metainfo.xml

cp linux/packaging/appimage/AppRun nesd.AppDir/AppRun

cp assets/logo.svg nesd.AppDir/dev.jpj.NESd.svg
cp assets/logo.svg nesd.AppDir/usr/share/icons/hicolor/scalable/apps/dev.jpj.NESd.svg

chmod +x nesd.AppDir/AppRun

appimagetool --no-appstream nesd.AppDir "$ARTIFACT".AppImage

mv ./*.AppImage "$ARTIFACT".linux-"$ARCH".AppImage
