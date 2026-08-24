#!/usr/bin/env bash

set -eux

repo_root=$(git rev-parse --show-toplevel)

cd "$repo_root/packages/nesd"

flutter=${FLUTTER:-flutter}

# only run web tests (everything else uses dart:io or native libraries)
$flutter test --platform chrome \
  test/util/wait_web_test.dart \
  test/nes/web_core_smoke_test.dart \
  test/nes/isolate/web_worker_smoke_test.dart \
  test/nes/isolate/local_nes_handle_frames_test.dart \
  test/nes/isolate/nes_bytes_test.dart \
  test/nes/isolate/nes_bytes_web_test.dart \
  test/nes/ppu/frame_buffer_memory_test.dart \
  test/nes/rewind/rewind_codec_test.dart \
  test/nes/serialization/nesd_uint64_test.dart \
  test/audio/silent_audio_sink_test.dart \
  test/audio/web_audio_queue_test.dart \
  test/audio/web_audio_device_smoke_test.dart
