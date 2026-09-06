@TestOn('browser')
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/audio/audio_output.dart';
import 'package:nesd/nes/apu/apu.dart';
import 'package:nesd_audio/nesd_audio.dart';

void main() {
  test('scheduled-buffer fallback opens and accepts samples', () {
    final audio = NesdAudio.open(
      sampleRate: apuSampleRate,
      channels: 1,
      bufferSamples: audioBufferSamples,
      recoverSamples: audioRecoverSamples,
      worklet: false,
    );

    expect(audio.capacity, audioBufferSamples);

    expect(audio.push(Float32List(800)), 800);
    expect(audio.filled, 800);
    expect(audio.underruns, 0);
    expect(audio.overruns, 0);

    audio.reset();

    expect(audio.filled, 0);

    audio.close();
  });
}
