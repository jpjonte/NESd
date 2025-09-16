#!/usr/bin/env bash
set -eo pipefail

# Portable runner delegating to Dart implementation.

ROM_PATH=${ROM_PATH:-"$1"}
FRAMES=${FRAMES:-240}
WARMUP=${WARMUP:-60}
RUNS=${RUNS:-6}

if [[ -z "$ROM_PATH" ]]; then
  echo "Usage: bin/perf/run_bench.sh <rom_path>" >&2
  exit 2
fi

fvm dart run bin/perf/run.dart \
  --rom "$ROM_PATH" --frames "$FRAMES" --warmup "$WARMUP" --runs "$RUNS"
