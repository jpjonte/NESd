#!/usr/bin/env bash
set -eo pipefail

# Runs the perf suite under Flutter's test environment so dart:ui is available.
# This executes bin/perf/bench_test.dart which reads bin/perf/suite.json
# and writes artifacts into bin/perf/results/.

fvm flutter test -r compact bin/perf/bench_test.dart

fvm dart run bin/perf/plot.dart
