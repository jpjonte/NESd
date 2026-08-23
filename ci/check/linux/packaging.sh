#!/usr/bin/env bash
set -euo pipefail

root=$(git rev-parse --show-toplevel)
app_root="$root/packages/nesd"
packaging="$app_root/linux/packaging"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fail() { echo "packaging: $*" >&2; exit 1; }

assert_file() { [ -f "$1" ] || fail "missing file: $1"; }

assert_grep() {
  grep -q -- "$1" "$2" || fail "expected '$1' in $2"
}

assert_no_token() {
  ! grep -Eq '@[A-Z_]+@' "$1" || fail "unsubstituted token in $1"
}

assert_fails() {
  if "$@" >/dev/null 2>&1; then
    fail "expected failure: $*"
  fi
}

# --- template.sh -----------------------------------------------------------

printf 'a=@A@\nb=@B_TWO@\n' > "$tmp/t.in"
bash "$packaging/template.sh" "$tmp/t.in" "$tmp/t.out" A=1 "B_TWO=two words"
assert_grep '^a=1$' "$tmp/t.out"
assert_grep '^b=two words$' "$tmp/t.out"

# A token without a value must fail, not ship.
assert_fails bash "$packaging/template.sh" "$tmp/t.in" "$tmp/t.bad" A=1
[ ! -f "$tmp/t.bad" ] || fail "template.sh left output behind on failure"

# --- render.sh -------------------------------------------------------------

check_render() {
  local flavor=$1 id=$2 app_id=$3 name=$4 exec=$5 logo=$6
  local share="$tmp/render-$flavor/share" out

  out=$(bash "$packaging/render.sh" "$flavor" "$exec" "$share")
  [ "$out" = "$id" ] || fail "render.sh $flavor printed '$out', want '$id'"

  local desktop="$share/applications/$id.desktop"
  local metainfo="$share/metainfo/$id.metainfo.xml"
  local icon="$share/icons/hicolor/scalable/apps/$id.svg"

  assert_file "$desktop"
  assert_file "$metainfo"
  assert_file "$icon"

  assert_grep "^Name=$name\$" "$desktop"
  assert_grep "^Icon=$id\$" "$desktop"
  assert_grep "^Exec=$exec %U\$" "$desktop"
  assert_grep "^StartupWMClass=$app_id\$" "$desktop"
  assert_no_token "$desktop"

  assert_grep "<id>$id</id>" "$metainfo"
  assert_grep "<name>$name</name>" "$metainfo"
  assert_grep "<launchable type=\"desktop-id\">$id.desktop</launchable>" \
    "$metainfo"
  assert_grep "<update_contact>" "$metainfo"
  assert_no_token "$metainfo"

  cmp -s "$icon" "$app_root/assets/$logo" || fail "$flavor icon is not $logo"
}

check_render prod dev.jpj.NESd dev.jpj.nesd NESd nesd logo.svg
check_render dev dev.jpj.NESd.dev dev.jpj.nesd.dev "NESd dev" nesd-dev \
  logo-dev.svg

assert_fails bash "$packaging/render.sh" beta nesd "$tmp/render-beta"

# --- deb templates ---------------------------------------------------------

bash "$packaging/template.sh" "$packaging/deb/control.in" "$tmp/control" \
  PACKAGE=dev.jpj.NESd.dev VERSION=1.2.3 ARCH=arm64 SIZE=4321
assert_grep '^Package: dev.jpj.NESd.dev$' "$tmp/control"
assert_grep '^Version: 1.2.3$' "$tmp/control"
assert_grep '^Architecture: arm64$' "$tmp/control"
assert_grep '^Installed-Size: 4321$' "$tmp/control"
assert_no_token "$tmp/control"

bash "$packaging/template.sh" "$packaging/deb/postinst.in" "$tmp/postinst" \
  PACKAGE=dev.jpj.NESd.dev BIN=nesd-dev
assert_grep '^ln -s /usr/share/dev.jpj.NESd.dev/nesd /usr/bin/nesd-dev$' \
  "$tmp/postinst"
assert_no_token "$tmp/postinst"

bash "$packaging/template.sh" "$packaging/deb/postrm.in" "$tmp/postrm" \
  BIN=nesd-dev
assert_grep '^rm /usr/bin/nesd-dev$' "$tmp/postrm"
assert_no_token "$tmp/postrm"

# --- flatpak/install.sh ----------------------------------------------------

# Builds a fake packages/nesd checkout with a prebuilt bundle for $arch
# and runs install.sh the way flatpak-builder does: cwd is the source
# tree, FLATPAK_* describe the build.
check_install() {
  local id=$1 flatpak_arch=$2 arch=$3 flavor=$4 name=$5
  local src="$tmp/src-$id" dest="$tmp/dest-$id"
  local bundle="$src/build/linux/$arch/$flavor/release/bundle"

  mkdir -p "$bundle/lib" "$src/linux" "$src/assets" "$dest"
  echo "binary $arch" > "$bundle/nesd"
  echo "lib" > "$bundle/lib/libapp.so"
  cp -r "$packaging" "$src/linux/packaging"
  cp "$app_root/assets/logo.svg" "$app_root/assets/logo-dev.svg" "$src/assets/"

  (
    cd "$src"
    FLATPAK_ID=$id FLATPAK_ARCH=$flatpak_arch FLATPAK_DEST=$dest \
      bash linux/packaging/flatpak/install.sh
  )

  assert_file "$dest/nesd"
  [ -x "$dest/nesd" ] || fail "$id: /app/nesd is not executable"
  assert_grep "^binary $arch\$" "$dest/nesd"
  assert_file "$dest/lib/libapp.so"
  [ "$(readlink "$dest/bin/nesd")" = /app/nesd ] || fail "$id: bin/nesd link"

  assert_file "$dest/share/applications/$id.desktop"
  assert_grep "^Name=$name\$" "$dest/share/applications/$id.desktop"
  assert_grep "^Exec=nesd %U\$" "$dest/share/applications/$id.desktop"
  assert_file "$dest/share/metainfo/$id.metainfo.xml"
  assert_grep "<id>$id</id>" "$dest/share/metainfo/$id.metainfo.xml"
  assert_file "$dest/share/icons/hicolor/scalable/apps/$id.svg"
}

check_install dev.jpj.NESd x86_64 x64 prod NESd
check_install dev.jpj.NESd.dev aarch64 arm64 dev "NESd dev"

bad_src="$tmp/src-dev.jpj.NESd"
(
  cd "$bad_src"
  assert_fails env FLATPAK_ID=dev.jpj.Other FLATPAK_ARCH=x86_64 \
    FLATPAK_DEST="$tmp/dest-bad-id" bash linux/packaging/flatpak/install.sh
  assert_fails env FLATPAK_ID=dev.jpj.NESd FLATPAK_ARCH=ppc64le \
    FLATPAK_DEST="$tmp/dest-bad-arch" bash linux/packaging/flatpak/install.sh
)

echo "packaging: ok"
