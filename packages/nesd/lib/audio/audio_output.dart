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
    bufferConstructor: (size) => Float32List(size),
    size: 2400, // 50 ms
  );

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
    audioStream.uninit();

    _audioBuffer.clear();

    _init();
  }

  void dispose() {
    audioStream.uninit();
  }

  void processSamples(Float32List samples) {
    final volumeApplied = Float32List.fromList(
      samples.map((s) => s * _volume).toList(),
    );

    _audioBuffer.write(volumeApplied);

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
    final flushSize = min(remaining, _audioBuffer.current);

    if (flushSize <= 0) {
      return;
    }

    audioStream.push(_audioBuffer.read(flushSize));
  }
}
