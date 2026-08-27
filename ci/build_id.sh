#!/usr/bin/env bash

set -euo pipefail

if [ "${GITHUB_REF_TYPE:-}" == "tag" ]; then
  exit 0
fi

if [ "${GITHUB_REF_NAME:-}" == "main" ]; then
  kind="nightly"
else
  kind="branch"
fi

echo "$kind-$(date -u +%Y%m%d)-$(git rev-parse --short HEAD)"
