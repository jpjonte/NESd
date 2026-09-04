import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/audio/audio_setpoint.dart';

void main() {
  test('small device reads keep the default setpoint', () {
    expect(audioSetpointFor(popMax: 96, capacity: 4800), 1200);
    expect(audioSetpointFor(popMax: 441, capacity: 4800), 1200);
  });

  test('a 20 ms mixer burst raises the setpoint to 2.5 bursts', () {
    expect(audioSetpointFor(popMax: 956, capacity: 4800), 2390);
  });

  test('never exceeds half the ring', () {
    expect(audioSetpointFor(popMax: 1920, capacity: 4800), 2400);
    expect(audioSetpointFor(popMax: 956, capacity: 2400), 1200);
  });

  test('the default is the pre-existing 25 ms latency', () {
    expect(defaultAudioSetpointSamples, 1200);
  });
}
