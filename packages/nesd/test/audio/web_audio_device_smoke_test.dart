import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/audio/audio_output.dart';

void main() {
  test('audio device opens and accepts samples', () {
    // Real device only on web (the AudioWorklet backend under test), do not
    // grab actual audio hardware.
    final audio = defaultNesdAudio(nullDevice: !kIsWeb);

    expect(audio.capacity, greaterThan(0));

    final written = audio.push(Float32List(800));

    expect(written, greaterThan(0));

    audio.close();
  });
}
