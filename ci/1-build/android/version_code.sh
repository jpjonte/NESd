#!/usr/bin/env bash
# Derive a Play versionCode from a semantic version.
#
#   X.Y.Z -> X*100000 + Y*1000 + Z*10

set -euo pipefail

version=${1:-}

if [[ ! $version =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
  echo "version_code: expected X.Y.Z, got '$version'" >&2
  exit 1
fi

major=${BASH_REMATCH[1]}
minor=${BASH_REMATCH[2]}
patch=${BASH_REMATCH[3]}

if [ "$minor" -gt 99 ] || [ "$patch" -gt 99 ]; then
  echo "version_code: minor and patch must be <= 99, got '$version'" >&2
  exit 1
fi

echo $(( major * 100000 + minor * 1000 + patch * 10 ))
