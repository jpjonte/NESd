import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart';
import 'package:nesd/audio/audio_output.dart';

class _FakeAudioStream implements AudioStream {
  int filledSize = 0;

  final List<Float32List> pushed = [];

  int initCount = 0;
  int uninitCount = 0;

  @override
  int init({
    int bufferMilliSec = 3000,
    int waitingBufferMilliSec = 100,
    int channels = 1,
    int sampleRate = 44100,
  }) {
    initCount++;

    return 0;
  }

  @override
  void uninit() {
    uninitCount++;
  }

  @override
  void resume() {}

  @override
  int push(Float32List buf) {
    // copy: the caller reuses its flush buffer between pushes
    pushed.add(Float32List.fromList(buf));

    return 0;
  }

  @override
  AudioStreamStat stat() => AudioStreamStat.empty();

  @override
  void resetStat() {}

  @override
  int getBufferSize() => 2400;

  @override
  int getBufferFilledSize() => filledSize;
}

void main() {
  late _FakeAudioStream stream;
  late AudioOutput output;

  setUp(() {
    stream = _FakeAudioStream();
    output = AudioOutput(audioStream: stream);
  });

  test('pushes as many samples as fit in the native buffer', () {
    stream.filledSize = 2000;

    output.processSamples(Float32List(800));

    expect(stream.pushed.single.length, 400);
  });

  test('keeps pushing immediately after an underrun', () {
    stream.filledSize = 0;

    output.processSamples(Float32List(800));

    expect(stream.pushed.single.length, 800);
  });

  test('retains pending samples while the native buffer is full', () {
    stream.filledSize = 2400;

    output.processSamples(Float32List(800));

    expect(stream.pushed, isEmpty);

    stream.filledSize = 0;

    output.processSamples(Float32List(0));

    expect(stream.pushed.single.length, 800);
  });

  test('bufferStatus sums native fill and pending samples', () {
    stream.filledSize = 2400;

    output.processSamples(Float32List(100));

    stream.filledSize = 1000;

    expect(output.bufferStatus, (fill: 1100, capacity: 2400));
  });

  test('applies volume in place before pushing', () {
    output.volume = 0.5;

    final samples = Float32List.fromList([1.0, -1.0, 0.5]);

    output.processSamples(samples);

    // the input buffer itself is mutated (documented contract)
    expect(samples, [0.5, -0.5, 0.25]);
    expect(stream.pushed.single, [0.5, -0.5, 0.25]);
  });

  test('leaves samples untouched at volume 1.0', () {
    final samples = Float32List.fromList([1.0, -1.0, 0.5]);

    output.processSamples(samples);

    expect(samples, [1.0, -1.0, 0.5]);
    expect(stream.pushed.single, [1.0, -1.0, 0.5]);
  });

  test('reset does not tear down the audio device', () {
    output.reset();

    expect(stream.uninitCount, 0);
    expect(stream.initCount, 1); // constructor only
  });
}
