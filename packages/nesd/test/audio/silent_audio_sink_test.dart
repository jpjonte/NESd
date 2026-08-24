import 'package:flutter_test/flutter_test.dart';
import 'package:nesd_audio/src/silent_audio_sink.dart';

void main() {
  late int clock;
  late SilentAudioSink sink;

  setUp(() {
    clock = 0;
    sink = SilentAudioSink(
      capacity: 2400,
      sampleRate: 48000,
      elapsedMicroseconds: () => clock,
    );
  });

  test('accepts samples up to capacity, then short-writes', () {
    expect(sink.push(2000), 2000);
    expect(sink.push(2000), 400);
    expect(sink.push(100), 0);
    expect(sink.filled, 2400);
  });

  test('consumes at the sample rate as the clock advances', () {
    sink.push(2400);

    clock = 25000; // 25 ms -> 1200 samples at 48 kHz

    expect(sink.filled, 1200);
    expect(sink.push(2400), 1200);
    expect(sink.filled, 2400);
  });

  test('drains to zero and never goes negative', () {
    sink.push(1000);

    clock = 1000000;

    expect(sink.filled, 0);
    expect(sink.push(500), 500);
  });

  test('a long idle period does not bank unlimited credit', () {
    sink.push(2400);

    clock = 10000000; // 10 s idle

    expect(sink.push(100000), 2400);
    expect(sink.filled, 2400);
  });
}
