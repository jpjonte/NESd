#!/usr/bin/env bash
set -euo pipefail

# Verifies that the given bundle is compatible with glibc and libstdc++ shipped by Ubuntu 22.04

if [ $# -ne 1 ]; then
  echo "usage: abi.sh BUNDLE_DIR" >&2
  exit 2
fi

bundle=$1
max_glibc="2.35"
max_glibcxx="3.4.30"
failed=0
checked=0

if ! command -v readelf >/dev/null; then
  echo "abi: readelf not found" >&2
  exit 2
fi

if [ ! -d "$bundle" ]; then
  echo "abi: no bundle at $bundle" >&2
  exit 2
fi

undefined_symbols() {
  local symbols
  symbols=$(readelf --dyn-syms -W "$1") || return 1
  grep ' UND ' <<< "$symbols" || true
}

newest() {
  grep -oE "$1_[0-9]+(\.[0-9]+)+" <<< "$2" | sed "s/^$1_//" | sort -V | tail -n 1 || true
}

too_new() {
  [ -n "$1" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n 1)" != "$2" ]
}

while IFS= read -r -d '' file; do
  [ "$(od -An -tx1 -N4 "$file")" = " 7f 45 4c 46" ] || continue

  checked=$((checked + 1))
  symbols=$(undefined_symbols "$file")
  glibc=$(newest GLIBC "$symbols")
  glibcxx=$(newest GLIBCXX "$symbols")

  if too_new "$glibc" "$max_glibc"; then
    echo "abi: $file needs GLIBC_$glibc (max $max_glibc)" >&2
    failed=1
  fi

  if too_new "$glibcxx" "$max_glibcxx"; then
    echo "abi: $file needs GLIBCXX_$glibcxx (max $max_glibcxx)" >&2
    failed=1
  fi
done < <(find "$bundle" -type f -print0)

if [ "$checked" -eq 0 ]; then
  echo "abi: no ELF files in $bundle" >&2
  exit 1
fi

if [ "$failed" -ne 0 ]; then
  exit 1
fi

echo "abi: ok ($checked ELF files)"
