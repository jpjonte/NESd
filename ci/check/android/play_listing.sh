#!/usr/bin/env bash
# Validate a gradle-play-publisher `play/` tree against Play's limits.
set -euo pipefail

root="${1:-packages/nesd/android/app/src/main/play}"
loc="$root/listings/en-US"
g="$loc/graphics"

fail() { echo "play_listing: $*" >&2; exit 1; }

command -v od >/dev/null 2>&1 || \
  fail "'od' not found on PATH — required for PNG header parsing"

char_count() {
  local file="$1" raw
  raw=$(LC_ALL=C.UTF-8 wc -m < "$file" | tr -d ' ')

  if [ -s "$file" ] && [ -z "$(tail -c 1 "$file")" ]; then
    echo $((raw - 1))
  else
    echo "$raw"
  fi
}

check_len() {
  local file="$1" max="$2" label="$3" n
  [ -f "$file" ] || fail "$label missing: $file"

  n=$(char_count "$file")

  [ "$n" -le "$max" ] || fail "$label too long ($n > $max): $file"
}

# PNG IHDR: bytes 16-19 width, 20-23 height, 25 colour type.
png_u32_be() {
  local b
  b=($(od -An -tu1 -N4 -j"$2" "$1"))

  echo $(( ${b[0]} * 16777216 + ${b[1]} * 65536 + ${b[2]} * 256 + ${b[3]} ))
}

png_dims() { echo "$(png_u32_be "$1" 16)x$(png_u32_be "$1" 20)"; }

# Color type 4 (gray + alpha) and 6 (RGBA) carry an alpha channel.
png_has_alpha() {
  case "$(od -An -tu1 -N1 -j25 "$1" | tr -d ' ')" in
    4|6) echo "yes" ;;
    *)   echo "no"  ;;
  esac
}

check_png() {
  local file="$1" want_w="$2" want_h="$3" want_alpha="$4" label="$5"
  [ -f "$file" ] || fail "$label missing: $file"

  local dims alpha
  dims=$(png_dims "$file")

  [ "$dims" = "${want_w}x${want_h}" ] || \
    fail "$label wrong dimensions (got $dims, want ${want_w}x${want_h})"

  alpha=$(png_has_alpha "$file")

  case "$want_alpha" in
    alpha)   [ "$alpha" = "yes" ] || fail "$label must have alpha: $file" ;;
    noalpha) [ "$alpha" = "no" ]  || fail "$label must have no alpha: $file" ;;
  esac
}

# ---- required metadata ----
for f in default-language.txt contact-email.txt contact-website.txt; do
  [ -f "$root/$f" ] || fail "missing: $root/$f"
done

# ---- text ----
check_len "$loc/title.txt"              30   "title"
check_len "$loc/short-description.txt"  80   "short description"
check_len "$loc/full-description.txt"   4000 "full description"

# ---- icon: 512x512, alpha, and <= 1024 KB ----
check_png "$g/icon/icon.png" 512 512 alpha "icon"

icon_kb=$(( $(wc -c < "$g/icon/icon.png") / 1024 ))

[ "$icon_kb" -le 1024 ] || \
  fail "icon too large (${icon_kb} KB > 1024 KB): $g/icon/icon.png"

# ---- feature graphic: 1024x500, no alpha ----
check_png "$g/feature-graphic/feature.png" 1024 500 noalpha "feature graphic"

# ---- phone screenshots: 2-8 PNGs, min side >= 320 ----
shopt -s nullglob
screenshots=("$g/phone-screenshots/"*.png)
shopt -u nullglob

n=${#screenshots[@]}

if [ "$n" -lt 2 ] || [ "$n" -gt 8 ]; then
  fail "phone-screenshots must contain 2-8 PNGs, found $n"
fi

for f in "${screenshots[@]+"${screenshots[@]}"}"; do
  dims=$(png_dims "$f")
  w="${dims%x*}"; h="${dims#*x}"

  if [ "$w" -lt 320 ] || [ "$h" -lt 320 ]; then
    fail "screenshot side < 320: $f ($dims)"
  fi
done

echo "play_listing: ok ($n screenshots)"
