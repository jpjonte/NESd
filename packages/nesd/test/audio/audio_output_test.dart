import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart';
import 'package:nesd/audio/audio_output.dart';

class _FakeAudioStream implements AudioStream {
  int filledSize = 0;

  final List<Float32List> pushed = [];

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
  int push(Float32List buf) {
    pushed.add(buf);

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
}
