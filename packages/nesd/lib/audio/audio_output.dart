import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:nesd/audio/pcm_recorder.dart';
import 'package:nesd/nes/apu/apu.dart';
import 'package:nesd/nes/apu/filter/filter.dart';
import 'package:nesd/nes/apu/filter/filter_chain.dart';
import 'package:nesd/nes/pacing_governor.dart';
import 'package:nesd/util/ring_buffer.dart';
import 'package:nesd_audio/nesd_audio.dart';

typedef AudioStats = ({
  int exhaustDelta,
  int fullDelta,
  int fillMin,
  int fillMax,
  int popMax,
});

/// Native ring capacity: 100 ms at the APU sample rate. The pacing setpoint
/// (defaultAudioSetpointSamples in audio_setpoint.dart) decides the actual
/// latency.
const audioBufferSamples = 4800;

/// Underrun recovery margin (on top of the largest device read): 20 ms.
const audioRecoverSamples = 960;

const lowPassCutoff = 14000.0;

NesdAudio defaultNesdAudio({bool nullDevice = false}) => NesdAudio.open(
  sampleRate: apuSampleRate,
  channels: 1,
  bufferSamples: audioBufferSamples,
  recoverSamples: audioRecoverSamples,
  nullDevice: nullDevice,
);

class AudioOutput {
  AudioOutput({required this.audio});

  final NesdAudio audio;

  final _audioBuffer = RingBuffer(
    buffer: Float32List(2400), // 50 ms
  );

  final _flushBuffer = Float32List(2400);

  double _volume = 1.0;

  final _lowPassFilter = FilterChain([
    Filter.lowPass(apuSampleRate.toDouble(), lowPassCutoff),
  ])..enabled = false;

  PcmRecorder? pcmRecorder;

  int? _fillMin;
  int? _fillMax;

  double get volume => _volume;

  set volume(double value) {
    _volume = value.clamp(0.0, 1.0);
  }

  bool get lowPassFilter => _lowPassFilter.enabled;

  set lowPassFilter(bool value) {
    _lowPassFilter.enabled = value;
  }

  AudioBufferStatus get bufferStatus =>
      (fill: audio.filled + _audioBuffer.current, capacity: audio.capacity);

  void reset() {
    _audioBuffer.clear();
    audio.reset();
  }

  void dispose() {
    pcmRecorder?.close();
    pcmRecorder = null;
    audio.close();
  }

  void processSamples(Float32List samples) {
    _trackFill();

    if (_volume != 1.0) {
      for (var i = 0; i < samples.length; i++) {
        samples[i] *= _volume;
      }
    }

    if (_lowPassFilter.enabled) {
      for (var i = 0; i < samples.length; i++) {
        samples[i] = _lowPassFilter.apply(samples[i]);
      }
    }

    pcmRecorder?.add(samples);

    _audioBuffer.write(samples);

    _flushSamples();
  }

  void _flushSamples() {
    final remaining = audio.capacity - audio.filled;
    final flushSize = min(
      min(remaining, _audioBuffer.current),
      _flushBuffer.length,
    );

    if (flushSize <= 0) {
      return;
    }

    final count = _audioBuffer.readInto(_flushBuffer, flushSize);

    audio.push(Float32List.sublistView(_flushBuffer, 0, count));
  }

  AudioStats takeStats() {
    final fill = bufferStatus.fill;
    final stats = (
      exhaustDelta: audio.underruns,
      fullDelta: audio.overruns,
      fillMin: _fillMin ?? fill,
      fillMax: _fillMax ?? fill,
      popMax: audio.popMax,
    );

    audio.resetStats();

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
