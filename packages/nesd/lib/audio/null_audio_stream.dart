import 'dart:typed_data';

import 'package:mp_audio_stream/mp_audio_stream.dart';

/// No-op [AudioStream] used when the real backend cannot be initialized.
///
/// `mp_audio_stream` resolves its FFI symbols via
/// `DynamicLibrary.executable()` on macOS/iOS, which under `flutter test`
/// points at the stock `flutter_tester` binary with no miniaudio symbols
/// compiled in. Spawning a `NesIsolate` with `disableAudio: true` swaps in
/// this stream so `AudioOutput` initializes without touching real audio
/// hardware. Values are inert no-ops chosen so `AudioOutput`'s flush math
/// degrades to its buffering path: `getBufferFilledSize()` always reports
/// 0, so `getBufferSize()`'s exact value never affects behavior.
class NullAudioStream implements AudioStream {
  @override
  int init({
    int bufferMilliSec = 3000,
    int waitingBufferMilliSec = 100,
    int channels = 1,
    int sampleRate = 44100,
  }) => 0;

  @override
  void uninit() {}

  @override
  void resume() {}

  @override
  int push(Float32List buf) => 0;

  @override
  AudioStreamStat stat() => AudioStreamStat.empty();

  @override
  void resetStat() {}

  @override
  int getBufferSize() => 2400;

  @override
  int getBufferFilledSize() => 0;
}
