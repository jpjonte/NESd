import 'dart:math';
import 'dart:typed_data';

import 'package:mp_audio_stream/mp_audio_stream.dart';
import 'package:nesd/audio/pcm_recorder.dart';
import 'package:nesd/nes/pacing_governor.dart';
import 'package:nesd/util/ring_buffer.dart';

typedef AudioStats = ({
  int exhaustDelta,
  int fullDelta,
  int fillMin,
  int fillMax,
});

class AudioOutput {
  AudioOutput({required this.audioStream}) {
    _init();
  }

  final AudioStream audioStream;

  final _audioBuffer = RingBuffer(
    buffer: Float32List(2400), // 50 ms
  );

  final _flushBuffer = Float32List(2400);

  double _volume = 1.0;

  PcmRecorder? pcmRecorder;

  int? _fillMin;
  int? _fillMax;

  double get volume => _volume;

  set volume(double value) {
    _volume = value.clamp(0.0, 1.0);
  }

  AudioBufferStatus get bufferStatus => (
    fill: audioStream.getBufferFilledSize() + _audioBuffer.current,
    capacity: audioStream.getBufferSize(),
  );

  void reset() {
    _audioBuffer.clear();
  }

  void dispose() {
    pcmRecorder?.close();
    pcmRecorder = null;
    audioStream.uninit();
  }

  void processSamples(Float32List samples) {
    _trackFill();

    if (_volume != 1.0) {
      for (var i = 0; i < samples.length; i++) {
        samples[i] *= _volume;
      }
    }

    pcmRecorder?.add(samples);

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

    audioStream.push(Float32List.sublistView(_flushBuffer, 0, count));
  }

  AudioStats takeStats() {
    final stat = audioStream.stat();

    audioStream.resetStat();

    final fill = bufferStatus.fill;
    final stats = (
      exhaustDelta: stat.exhaust,
      fullDelta: stat.full,
      fillMin: _fillMin ?? fill,
      fillMax: _fillMax ?? fill,
    );

    _fillMin = null;
    _fillMax = null;

    return stats;
  }

  void _trackFill() {
    final fill = bufferStatus.fill;

    _fillMin = _fillMin == null ? fill : min(_fillMin!, fill);
    _fillMax = _fillMax == null ? fill : max(_fillMax!, fill);
  }
}
