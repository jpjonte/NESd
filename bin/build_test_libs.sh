#!/usr/bin/env bash
#
# Builds the host copy of the nesd_audio library that `flutter test`
# loads (see packages/nesd/test/flutter_test_config.dart) and runs the
# native spsc_ring stress test.
set -euo pipefail

cd "$(dirname "$0")/.."

src=packages/nesd_audio/src
out=packages/nesd_audio/build/test

cmake -S "$src" -B "$out" -DCMAKE_BUILD_TYPE=Release \
  -DNESD_AUDIO_BUILD_TESTS=ON
cmake --build "$out" --config Release

if [[ -x "$out/spsc_ring_test" ]]; then
  "$out/spsc_ring_test"
else
  "$out/Release/spsc_ring_test.exe"
fi
