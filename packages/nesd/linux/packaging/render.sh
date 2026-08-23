#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 3 ]; then
  echo "usage: render.sh FLAVOR EXEC SHARE_DIR" >&2
  exit 2
fi

flavor=$1
exec_cmd=$2
share=$3

packaging=$(cd "$(dirname "$0")" && pwd)
assets="$packaging/../../assets"

case "$flavor" in
  prod)
    id="dev.jpj.NESd"
    app_id="dev.jpj.nesd"
    name="NESd"
    logo="logo.svg"
    ;;
  dev)
    id="dev.jpj.NESd.dev"
    app_id="dev.jpj.nesd.dev"
    name="NESd dev"
    logo="logo-dev.svg"
    ;;
  *)
    echo "render.sh: unknown flavor '$flavor' (want prod or dev)" >&2
    exit 1
    ;;
esac

bash "$packaging/template.sh" "$packaging/nesd.desktop.in" \
  "$share/applications/$id.desktop" \
  "ID=$id" "APP_ID=$app_id" "NAME=$name" "EXEC=$exec_cmd"

bash "$packaging/template.sh" "$packaging/nesd.metainfo.xml.in" \
  "$share/metainfo/$id.metainfo.xml" \
  "ID=$id" "NAME=$name"

mkdir -p "$share/icons/hicolor/scalable/apps"
cp "$assets/$logo" "$share/icons/hicolor/scalable/apps/$id.svg"

echo "$id"
