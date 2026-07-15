import 'dart:math';
import 'dart:typed_data';

import 'package:mp_audio_stream/mp_audio_stream.dart';
import 'package:nesd/nes/pacing_governor.dart';
import 'package:nesd/util/ring_buffer.dart';

class AudioOutput {
  AudioOutput({required this.audioStream}) {
    _init();
  }

  final AudioStream audioStream;

  final _audioBuffer = RingBuffer(
    buffer: Float32List(2400), // 50 ms
  );

  // reused for every flush to avoid a per-frame allocation
  final _flushBuffer = Float32List(2400);

  double _volume = 1.0;

  double get volume => _volume;

  set volume(double value) {
    _volume = value.clamp(0.0, 1.0);
  }

  AudioBufferStatus get bufferStatus => (
    fill: audioStream.getBufferFilledSize() + _audioBuffer.current,
    capacity: audioStream.getBufferSize(),
  );

  void reset() {
    // Keep the device running: re-initializing miniaudio can take tens of
    // milliseconds on Android. Stale samples (max 50 ms) drain naturally.
    _audioBuffer.clear();
  }

  void dispose() {
    audioStream.uninit();
  }

  /// Applies volume in place: [samples] is uniquely owned by the audio
  /// path once it reaches this method and may be mutated.
  void processSamples(Float32List samples) {
    if (_volume != 1.0) {
      for (var i = 0; i < samples.length; i++) {
        samples[i] *= _volume;
      }
    }

    _audioBuffer.write(samples);

    _flushSamples();
  }

  void _init() {
    audioStream
      ..init(bufferMilliSec: 50, waitingBufferMilliSec: 20, sampleRate: 48000)
      ..resume();
  }

  void _flushSamples() {
    final remaining =
        audioStream.getBufferSize() - audioStream.getBufferFilledSize();
    final flushSize = min(
      min(remaining, _audioBuffer.current),
      _flushBuffer.length,
    );

    if (flushSize <= 0) {
      return;
    }

    final count = _audioBuffer.readInto(_flushBuffer, flushSize);

    // push cannot reject: flushSize is capped by the native buffer's free
    // space read on this same thread, and only the consumer (audio
    // callback) mutates fill concurrently - it can only make more room.
    audioStream.push(Float32List.sublistView(_flushBuffer, 0, count));
  }
}
