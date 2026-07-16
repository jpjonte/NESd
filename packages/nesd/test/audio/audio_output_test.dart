import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart';
import 'package:nesd/audio/audio_output.dart';
import 'package:nesd/audio/pcm_recorder.dart';

class _FakeAudioStream implements AudioStream {
  int filledSize = 0;

  final List<Float32List> pushed = [];

  int initCount = 0;
  int uninitCount = 0;

  AudioStreamStat nextStat = AudioStreamStat.empty();

  int resetStatCount = 0;

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
  AudioStreamStat stat() => nextStat;

  @override
  void resetStat() {
    resetStatCount++;
  }

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

  test('takeStats returns native counters and resets them', () {
    stream.nextStat = AudioStreamStat(full: 1, exhaust: 3);

    final stats = output.takeStats();

    expect(stats.exhaustDelta, 3);
    expect(stats.fullDelta, 1);
    expect(stream.resetStatCount, 1);
  });

  test('takeStats tracks min and max fill across frames', () {
    stream.filledSize = 500;
    output.processSamples(Float32List(0));

    stream.filledSize = 1500;
    output.processSamples(Float32List(0));

    final stats = output.takeStats();

    expect(stats.fillMin, 500);
    expect(stats.fillMax, 1500);
  });

  test('takeStats without samples reports current fill for both', () {
    stream.filledSize = 700;

    final stats = output.takeStats();

    expect(stats.fillMin, 700);
    expect(stats.fillMax, 700);
  });

  test('fill window resets between takeStats calls', () {
    stream.filledSize = 100;
    output
      ..processSamples(Float32List(0))
      ..takeStats();

    stream.filledSize = 900;
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
