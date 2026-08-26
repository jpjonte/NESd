import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/apu.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/fast_forward_speed.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../ui/mocks.dart';

/// Manual clock: time passes only when the test advances it.
class _FakeClock implements Stopwatch {
  int _micros = 0;
  bool _running = false;

  void advance(Duration duration) => _micros += duration.inMicroseconds;

  @override
  int get elapsedMicroseconds => _micros;

  @override
  Duration get elapsed => Duration(microseconds: _micros);

  @override
  int get elapsedMilliseconds => _micros ~/ 1000;

  @override
  int get elapsedTicks => _micros;

  @override
  int get frequency => Duration.microsecondsPerSecond;

  @override
  bool get isRunning => _running;

  @override
  void reset() => _micros = 0;

  @override
  void start() => _running = true;

  @override
  void stop() => _running = false;
}

Cartridge loadNestest() {
  const path = '../../roms/test/nestest/nestest.nes';

  final factory = CartridgeFactory(database: MockNesDatabase());

  return factory.fromFile(
    const FilesystemFile(path: path, name: path, type: FilesystemFileType.file),
    File(path).readAsBytesSync(),
  )..databaseEntry = null;
}

void main() {
  test(
    'sleepTime follows the governor drain law when the buffer is full',
    () async {
      final eventBus = EventBus();

      // fill == capacity => hard drain: (2400 - 1200) / 48000 s = 25ms,
      // independent of elapsed time, so the assertion is deterministic.
      final nes = NES(
        cartridge: loadNestest(),
        eventBus: eventBus,
        audioFillProbe: () => (fill: 2400, capacity: 2400),
      );

      final firstFrame = eventBus.stream.firstWhere(
        (event) => event is FrameNesEvent,
      );

      nes.reset();

      final event =
          await firstFrame.timeout(const Duration(seconds: 30))
              as FrameNesEvent;

      nes.stop();

      expect(event.sleepTime, const Duration(microseconds: 25000));
    },
  );

  test('sleep overshoot is charged to the next frame', () async {
    final eventBus = EventBus();
    final clock = _FakeClock();
    const overshoot = Duration(milliseconds: 5);

    // The clock advances only while sleeping, so emulation work is
    // free and every sleep overshoots by a fixed amount.
    Future<void> sleep(Duration duration) async {
      clock.advance(duration + overshoot);

      await Future<void>.delayed(Duration.zero);
    }

    final nes = NES(
      cartridge: loadNestest(),
      eventBus: eventBus,
      clock: clock,
      sleep: sleep,
    );

    final secondFrame = eventBus.stream
        .where((event) => event is FrameNesEvent)
        .cast<FrameNesEvent>()
        .take(2)
        .last;

    nes.reset();

    final second = await secondFrame.timeout(const Duration(seconds: 30));

    nes.stop();

    // Frame 2's measured work time must be exactly frame 1's sleep
    // overshoot, shortening its sleep by the same amount.
    final targetMicros =
        second.samples.length * Duration.microsecondsPerSecond / apuSampleRate;

    expect(
      second.sleepTime,
      Duration(microseconds: targetMicros.round()) - overshoot,
    );
  });

  test('fastForward at a finite speed emits decimated samples and '
      'governor-driven sleep', () async {
    final eventBus = EventBus();

    final nes = NES(
      cartridge: loadNestest(),
      eventBus: eventBus,
      audioFillProbe: () => (fill: 2400, capacity: 2400),
    );

    final fastForwardFrame = eventBus.stream.firstWhere(
      (event) =>
          event is FrameNesEvent &&
          event.samples.isNotEmpty &&
          event.samples.length < 500,
    );

    nes
      ..reset()
      ..fastForwardSpeed = FastForwardSpeed.x2
      ..fastForward = true;

    final event =
        await fastForwardFrame.timeout(const Duration(seconds: 30))
            as FrameNesEvent;

    nes.stop();

    expect(event.samples.length, inInclusiveRange(300, 500));
    expect(event.sleepTime, const Duration(microseconds: 25000));
  });

  test('fastForward at max speed emits empty samples and zero '
      'sleep', () async {
    final eventBus = EventBus();
    final nes = NES(cartridge: loadNestest(), eventBus: eventBus);

    final fastForwardFrame = eventBus.stream.firstWhere(
      (event) => event is FrameNesEvent && event.samples.isEmpty,
    );

    // reset() clears fastForward, so enable it after the loop starts.
    nes
      ..reset()
      ..fastForwardSpeed = FastForwardSpeed.max
      ..fastForward = true;

    final event =
        await fastForwardFrame.timeout(const Duration(seconds: 30))
            as FrameNesEvent;

    nes.stop();

    expect(event.samples, isEmpty);
    expect(event.sleepTime, Duration.zero);
  });
}
