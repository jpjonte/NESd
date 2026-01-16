#!/usr/bin/env bash
set -eo pipefail

repo_root=$(git rev-parse --show-toplevel)
export NESD_WORKSPACE_ROOT="$repo_root"

# Runs the perf suite under Flutter's test environment so dart:ui is available.
# This executes bin/perf/bench_test.dart which reads bin/perf/suite.json
# and writes artifacts into bin/perf/results/.

pushd "$repo_root/packages/nesd" >/dev/null
fvm flutter test -r compact ../../bin/perf/bench_test.dart
popd >/dev/null

fvm dart run bin/perf/plot.dart
