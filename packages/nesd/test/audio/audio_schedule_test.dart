import 'package:flutter_test/flutter_test.dart';
import 'package:nesd_audio/src/audio_schedule.dart';

void main() {
  late double clock;
  late AudioSchedule schedule;

  setUp(() {
    clock = 1.0;
    schedule = AudioSchedule(
      capacity: 2400,
      sampleRate: 48000,
      recoverSamples: 960,
      currentTime: () => clock,
    );
  });

  test('the first chunk starts a recovery margin after the clock', () {
    final slot = schedule.push(800);

    expect(slot.samples, 800);
    expect(slot.startTime, closeTo(1.02, 1e-9));
    expect(schedule.underruns, 0);
  });

  test('consecutive chunks are scheduled back to back', () {
    schedule.push(800);

    final slot = schedule.push(400);

    expect(slot.startTime, closeTo(1.02 + 800 / 48000, 1e-9));
  });

  test('filled counts scheduled samples the clock has not played yet', () {
    schedule.push(2400);

    expect(schedule.filled, 2400);

    clock = 1.01; // still inside the recovery margin

    expect(schedule.filled, 2400);

    clock = 1.03; // 10 ms into playback: 480 samples played

    expect(schedule.filled, 1920);
  });

  test('filled drains to zero and never goes negative', () {
    schedule.push(1000);

    clock = 5.0;

    expect(schedule.filled, 0);
  });

  test('push fills up to capacity and short-writes past it', () {
    expect(schedule.push(2000).samples, 2000);
    expect(schedule.push(2000).samples, 400);
    expect(schedule.overruns, 1);
    expect(schedule.push(10).samples, 0);
    expect(schedule.overruns, 2);
    expect(schedule.filled, 2400);
  });

  test('a push after a drain counts one underrun and re-anchors', () {
    schedule.push(480); // plays 1.02 .. 1.03

    clock = 2.0;

    final slot = schedule.push(480);

    expect(schedule.underruns, 1);
    expect(slot.startTime, closeTo(2.02, 1e-9));
    expect(schedule.filled, 480);

    // one underrun per starvation event
    expect(schedule.push(480).startTime, closeTo(2.02 + 480 / 48000, 1e-9));
    expect(schedule.underruns, 1);
  });

  test('a push within one render quantum of the playhead re-anchors', () {
    schedule.push(480); // plays 1.02 .. 1.03

    clock = 1.028; // 96 samples left, less than the 128-frame quantum

    final slot = schedule.push(480);

    expect(schedule.underruns, 1);
    expect(slot.startTime, closeTo(1.048, 1e-9));
  });

  test('a push with more than a quantum left keeps the schedule', () {
    schedule.push(480); // plays 1.02 .. 1.03

    clock = 1.025; // 240 samples left

    final slot = schedule.push(480);

    expect(schedule.underruns, 0);
    expect(slot.startTime, closeTo(1.03, 1e-9));
  });

  test('a push with exactly a quantum left keeps the schedule', () {
    schedule.push(480); // plays 1.02 .. 1.03

    clock = 1.02 + 352 / 48000; // 128 samples left

    final slot = schedule.push(480);

    expect(schedule.underruns, 0);
    expect(slot.startTime, closeTo(1.03, 1e-9));
  });

  test('small chunks inside the recovery margin do not re-anchor', () {
    schedule.push(100);

    final slot = schedule.push(100);

    expect(schedule.underruns, 0);
    expect(slot.startTime, closeTo(1.02 + 100 / 48000, 1e-9));
  });

  test('start times do not drift over a long run', () {
    var total = 0;
    var slot = schedule.push(800);

    for (var i = 0; i < 100000; i++) {
      total += slot.samples;
      clock += 800 / 48000;
      slot = schedule.push(800);
    }

    expect(schedule.underruns, 0);
    expect(slot.startTime, closeTo(1.02 + total / 48000, 1e-9));
  });

  test('reset drops the schedule without counting an underrun', () {
    schedule
      ..push(2400)
      ..reset();

    expect(schedule.filled, 0);

    clock = 1.5;

    final slot = schedule.push(100);

    expect(slot.startTime, closeTo(1.52, 1e-9));
    expect(schedule.underruns, 0);
  });

  test('resetStats clears counters but not fill', () {
    schedule
      ..push(2400)
      ..push(100); // overrun

    clock = 5.0;

    schedule
      ..push(100) // underrun
      ..resetStats();

    expect(schedule.underruns, 0);
    expect(schedule.overruns, 0);
    expect(schedule.filled, 100);
  });
}
