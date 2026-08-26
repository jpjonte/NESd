#!/usr/bin/env bash
#
# Builds the host copy of the nesd_audio library that `flutter test`
# loads (see packages/nesd/test/flutter_test_config.dart) and runs the
# native nesd_audio tests.
set -euo pipefail

cd "$(dirname "$0")/.."

src=packages/nesd_audio/src
out=packages/nesd_audio/build/test

cmake -S "$src" -B "$out" -DCMAKE_BUILD_TYPE=Release \
  -DNESD_AUDIO_BUILD_TESTS=ON
cmake --build "$out" --config Release

for test in spsc_ring_test nesd_audio_core_test; do
  if [[ -x "$out/$test" ]]; then
    "$out/$test"
  else
    "$out/Release/$test.exe"
  fi
done
