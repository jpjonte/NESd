import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/audio/audio_output.dart';
import 'package:nesd/audio/pcm_recorder.dart';
import 'package:nesd_audio/nesd_audio.dart';

class _FakeNesdAudio implements NesdAudio {
  int filledValue = 0;
  int underrunsValue = 0;
  int overrunsValue = 0;
  int popMaxValue = 0;
  int closeCount = 0;
  int resetCount = 0;
  int resetStatsCount = 0;

  final List<Float32List> pushed = [];

  @override
  int get capacity => 2400;

  @override
  int get filled => filledValue;

  @override
  int get underruns => underrunsValue;

  @override
  int get overruns => overrunsValue;

  @override
  int get popMax => popMaxValue;

  @override
  int get restarts => 0;

  @override
  NesdAudioState get state => NesdAudioState.nullDevice;

  @override
  int push(Float32List samples) {
    // copy: the caller reuses its flush buffer between pushes
    pushed.add(Float32List.fromList(samples));

    return samples.length;
  }

  @override
  void reset() {
    resetCount++;
  }

  @override
  void resetStats() {
    resetStatsCount++;
    underrunsValue = 0;
    overrunsValue = 0;
    popMaxValue = 0;
  }

  @override
  void close() {
    closeCount++;
  }
}

void main() {
  late _FakeNesdAudio audio;
  late AudioOutput output;

  setUp(() {
    audio = _FakeNesdAudio();
    output = AudioOutput(audio: audio);
  });

  test('pushes as many samples as fit in the native buffer', () {
    audio.filledValue = 2000;

    output.processSamples(Float32List(800));

    expect(audio.pushed.single.length, 400);
  });

  test('keeps pushing immediately after an underrun', () {
    audio.filledValue = 0;

    output.processSamples(Float32List(800));

    expect(audio.pushed.single.length, 800);
  });

  test('retains pending samples while the native buffer is full', () {
    audio.filledValue = 2400;

    output.processSamples(Float32List(800));

    expect(audio.pushed, isEmpty);

    audio.filledValue = 0;

    output.processSamples(Float32List(0));

    expect(audio.pushed.single.length, 800);
  });

  test('bufferStatus sums native fill and pending samples', () {
    audio.filledValue = 2400;

    output.processSamples(Float32List(100));

    audio.filledValue = 1000;

    expect(output.bufferStatus, (fill: 1100, capacity: 2400));
  });

  test('applies volume in place before pushing', () {
    output.volume = 0.5;

    final samples = Float32List.fromList([1.0, -1.0, 0.5]);

    output.processSamples(samples);

    // the input buffer itself is mutated (documented contract)
    expect(samples, [0.5, -0.5, 0.25]);
    expect(audio.pushed.single, [0.5, -0.5, 0.25]);
  });

  test('leaves samples untouched at volume 1.0', () {
    final samples = Float32List.fromList([1.0, -1.0, 0.5]);

    output.processSamples(samples);

    expect(samples, [1.0, -1.0, 0.5]);
    expect(audio.pushed.single, [1.0, -1.0, 0.5]);
  });

  test('low pass filter is off by default', () {
    expect(output.lowPassFilter, isFalse);
  });

  test('attenuates high frequencies while the low pass filter is on', () {
    output.lowPassFilter = true;

    final samples = Float32List(64);

    for (var i = 0; i < samples.length; i++) {
      samples[i] = i.isEven ? 1.0 : -1.0;
    }

    output.processSamples(samples);

    expect(samples.last.abs(), lessThan(0.05));
  });

  test('passes low frequencies through while the low pass filter is on', () {
    output.lowPassFilter = true;

    final samples = Float32List(64)..fillRange(0, 64, 0.5);

    output.processSamples(samples);

    expect(samples.last, closeTo(0.5, 0.05));
  });

  test('reset flushes the backend without tearing it down', () {
    output.reset();

    expect(audio.resetCount, 1);
    expect(audio.closeCount, 0);
  });

  test('dispose closes the stream', () {
    output.dispose();

    expect(audio.closeCount, 1);
  });

  test('takeStats returns native counters and resets them', () {
    audio
      ..underrunsValue = 3
      ..overrunsValue = 1
      ..popMaxValue = 1700;

    final stats = output.takeStats();

    expect(stats.exhaustDelta, 3);
    expect(stats.fullDelta, 1);
    expect(stats.popMax, 1700);
    expect(audio.resetStatsCount, 1);
  });

  test('takeStats tracks min and max fill across frames', () {
    audio.filledValue = 500;
    output.processSamples(Float32List(0));

    audio.filledValue = 1500;
    output.processSamples(Float32List(0));

    final stats = output.takeStats();

    expect(stats.fillMin, 500);
    expect(stats.fillMax, 1500);
  });

  test('takeStats without samples reports current fill for both', () {
    audio.filledValue = 700;

    final stats = output.takeStats();

    expect(stats.fillMin, 700);
    expect(stats.fillMax, 700);
  });

  test('fill window resets between takeStats calls', () {
    audio.filledValue = 100;
    output
      ..processSamples(Float32List(0))
      ..takeStats();

    audio.filledValue = 900;
    output.processSamples(Float32List(0));

    final stats = output.takeStats();

    expect(stats.fillMin, 900);
    expect(stats.fillMax, 900);
  });

  test('tees post-volume samples to the PCM recorder', () {
    final dir = Directory.systemTemp.createTempSync('nesd_audio');
    addTearDown(() => dir.deleteSync(recursive: true));

    final path = '${dir.path}/a.pcm';

    output
      ..volume = 0.5
      ..pcmRecorder = PcmRecorder(path: path)
      ..processSamples(Float32List.fromList([1.0, -1.0]));

    output.pcmRecorder!.close();

    final floats = File(path).readAsBytesSync().buffer.asFloat32List();

    expect(floats, [0.5, -0.5]);
  });
}
