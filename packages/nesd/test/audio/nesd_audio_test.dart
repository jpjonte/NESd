import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd_audio/nesd_audio.dart';

void main() {
  test('null device plays pushed samples through the real library', () async {
    final audio = NesdAudio.open(
      sampleRate: 48000,
      channels: 1,
      bufferSamples: 2400,
      recoverSamples: 960,
      nullDevice: true,
    );

    addTearDown(audio.close);

    expect(audio.state, NesdAudioState.nullDevice);
    expect(audio.capacity, 2400);
    expect(audio.restarts, 0);

    final samples = Float32List.fromList(
      List.generate(2400, (i) => sin(2 * pi * 440 * i / 48000)),
    );

    expect(audio.push(samples), 2400);

    // The null device consumes in real time: 2400 samples at 48 kHz
    // drain within 50 ms. Generous slack for CI.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    expect(audio.filled, 0);
    expect(audio.underruns, greaterThan(0));
    expect(audio.popMax, greaterThan(0));

    audio.resetStats();

    expect(audio.underruns, 0);
    expect(audio.popMax, 0);
  });

  test('short writes count as overruns', () {
    final audio = NesdAudio.open(
      sampleRate: 48000,
      channels: 1,
      bufferSamples: 2400,
      recoverSamples: 960,
      nullDevice: true,
    );

    addTearDown(audio.close);

    final samples = Float32List(2400);

    audio.push(samples);

    expect(audio.push(samples), lessThan(2400));
    expect(audio.overruns, greaterThan(0));
  });
}
