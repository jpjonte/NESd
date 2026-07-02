import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/pacing_governor.dart';

void main() {
  // Defaults: 48kHz, gain 0.1, setpoint 50%, drain guard 85%, max 50ms.
  // 800 samples => 16666.67us open-loop frame budget.
  const governor = PacingGovernor();

  test('sleeps for the remaining frame budget without audio feedback', () {
    final sleep = governor.sleepFor(
      samplesProduced: 800,
      elapsed: const Duration(microseconds: 10000),
    );

    expect(sleep, const Duration(microseconds: 6667));
  });

  test('clamps to zero when the frame ran over budget', () {
    final sleep = governor.sleepFor(
      samplesProduced: 800,
      elapsed: const Duration(microseconds: 20000),
    );

    expect(sleep, Duration.zero);
  });

  test('leaves pacing unchanged at the fill setpoint', () {
    final sleep = governor.sleepFor(
      samplesProduced: 800,
      elapsed: const Duration(microseconds: 10000),
      audio: (fill: 1200, capacity: 2400),
    );

    expect(sleep, const Duration(microseconds: 6667));
  });

  test('speeds up when the buffer is under-filled', () {
    // error = 720 - 1200 = -480 => correction -1000us
    final sleep = governor.sleepFor(
      samplesProduced: 800,
      elapsed: const Duration(microseconds: 10000),
      audio: (fill: 720, capacity: 2400),
    );

    expect(sleep, const Duration(microseconds: 5667));
  });

  test('slows down when the buffer is over-filled', () {
    // error = 1680 - 1200 = 480 => correction +1000us
    final sleep = governor.sleepFor(
      samplesProduced: 800,
      elapsed: const Duration(microseconds: 10000),
      audio: (fill: 1680, capacity: 2400),
    );

    expect(sleep, const Duration(microseconds: 7667));
  });

  test('drains deterministically above the drain threshold', () {
    // fill 2160 >= 0.85 * 2400 (2040); error 960 => 20000us, elapsed
    // ignored.
    final sleep = governor.sleepFor(
      samplesProduced: 800,
      elapsed: Duration.zero,
      audio: (fill: 2160, capacity: 2400),
    );

    expect(sleep, const Duration(microseconds: 20000));
  });

  test('never sleeps longer than maxSleep', () {
    // error 4800 => 100000us, clamped to 50ms.
    final sleep = governor.sleepFor(
      samplesProduced: 800,
      elapsed: Duration.zero,
      audio: (fill: 9600, capacity: 9600),
    );

    expect(sleep, const Duration(milliseconds: 50));
  });

  test('runs flat out when the buffer is empty after a stall', () {
    final sleep = governor.sleepFor(
      samplesProduced: 800,
      elapsed: const Duration(microseconds: 16000),
      audio: (fill: 0, capacity: 2400),
    );

    expect(sleep, Duration.zero);
  });
}
