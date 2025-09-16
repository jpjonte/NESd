#!/usr/bin/env bash

version=$1

if [ -z "$version" ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Version must have format x.y.z"
    exit 1
fi

if ! command -v yq &> /dev/null
then
    echo "yq could not be found"
    exit
fi

date=$(date +'%Y-%m-%d')

sed -i '' -e 's/\[Unreleased\]/['"$version"'] - '"$date"'/' CHANGELOG.md

sed -i '' -e '/Version/s/.*/Version: '"$version"'/' linux/packaging/deb/control-x64
sed -i '' -e '/Version/s/.*/Version: '"$version"'/' linux/packaging/deb/control-arm64
sed -i '' -e '/Version/s/.*/Version: '"$version"'/' linux/packaging/rpm/nesd.spec

awk '
BEGIN {
  tag = "<releases>\n        <release version=\"'$version'\" date=\"'$date'\" />"
}
{
  gsub("<releases>", tag);
  print
}
' linux/packaging/dev.jpj.NESd.metainfo.xml > metainfo.xml

mv -f metainfo.xml linux/packaging/dev.jpj.NESd.metainfo.xml

sed -i '' -e '/version:/s/.*/version: '"$version"'/' pubspec.yaml
