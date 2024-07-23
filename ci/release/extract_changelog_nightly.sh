#!/usr/bin/env sh

set -eux

{
  echo "changes<<EOF"
  awk '
  BEGIN {
    inside_latest_version = 0
  }
  /^## \[Unreleased]/ {
    if (inside_latest_version)
      exit
    else
      inside_latest_version = 1
      next
  }
  /^## \[[0-9]+\.[0-9]+\.[0-9]+\]/ {
    if (inside_latest_version)
      exit
  }
  {
    if (inside_latest_version)
      print
  }
  ' "CHANGELOG.md"
  echo "EOF"
} >> "$GITHUB_OUTPUT"
