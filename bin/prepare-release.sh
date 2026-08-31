#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

changelog=CHANGELOG.md
pubspec=packages/nesd/pubspec.yaml
metainfo=packages/nesd/linux/packaging/nesd.metainfo.xml.in

die() {
  echo "prepare-release: $*" >&2
  exit 1
}

version=${1:-}
date=${2:-$(date +'%Y-%m-%d')}

if [ -z "$version" ]; then
  die "usage: $(basename "$0") X.Y.Z [YYYY-MM-DD]"
fi

if [[ ! $date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  die "date must be YYYY-MM-DD, got '$date'"
fi

bash ci/1-build/android/version_code.sh "$version" > /dev/null

for file in "$changelog" "$pubspec" "$metainfo"; do
  if [ ! -f "$file" ]; then
    die "no such file: $file"
  fi
done

if ! grep -q '^## \[Unreleased\]$' "$changelog"; then
  die "no '## [Unreleased]' section in $changelog"
fi

if grep -q "^## \[$version\]" "$changelog"; then
  die "$changelog already has a $version section"
fi

if grep -q "version=\"$version\"" "$metainfo"; then
  die "$metainfo already lists $version"
fi

if sed --version > /dev/null 2>&1; then
  sedi=(sed -i)
else
  sedi=(sed -i '')
fi

"${sedi[@]}" -e "s|^## \[Unreleased\]$|## [$version] - $date|" "$changelog"

"${sedi[@]}" -e "s|^version: .*|version: $version|" "$pubspec"

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

awk -v tag="        <release version=\"$version\" date=\"$date\" />" '
  { print }
  !inserted && /^[[:space:]]*<releases>[[:space:]]*$/ {
    print tag
    inserted = 1
  }
' "$metainfo" > "$tmp"

cat "$tmp" > "$metainfo"

if ! grep -q "^## \[$version\] - $date$" "$changelog"; then
  die "failed to write the $version header to $changelog"
fi

if ! grep -q "^version: $version$" "$pubspec"; then
  die "failed to write version $version to $pubspec"
fi

if ! grep -q "version=\"$version\" date=\"$date\"" "$metainfo"; then
  die "failed to add the $version release to $metainfo"
fi

cat <<EOF
prepare-release: bumped to $version ($date)
  $changelog
  $pubspec
  $metainfo

Review the changelog, then:
  git commit -am "Release NESd $version"
  git tag $version
  git push origin main && git push origin $version
EOF
