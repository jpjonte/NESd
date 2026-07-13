import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/event/nes_event.dart';

import '../test_roms/rom_robot.dart';

void main() {
  test('state getter captures the live emulator state on demand', () async {
    final robot = RomRobot('../../roms/test/nestest/nestest.nes');
    final nes = robot.nes..stop();

    await Future<void>.delayed(Duration.zero);

    nes.on = true;
    nes.cpu.ram[0] = 0x11;

    final first = nes.state;

    nes.cpu.ram[0] = 0x22;

    final second = nes.state;

    expect(first, isNotNull);
    expect(second, isNotNull);
    // both captures alias the live RAM: fresh capture, not a stale
    // per-frame snapshot
    expect(second!.cpuState.ram[0], 0x22);
    expect(identical(first, second), isFalse);

    nes.on = false;
  });

  test('rewind buffer fills when rewind is enabled', () async {
    final robot = RomRobot('../../roms/test/nestest/nestest.nes');
    final nes = robot.nes
      ..rewindEnabled = true
      ..fastForward = true;

    final events = await nes.eventBus.stream
        .where((event) => event is FrameNesEvent)
        .cast<FrameNesEvent>()
        .take(10)
        .toList()
        .timeout(const Duration(seconds: 60));

    nes.stop();

    await Future<void>.delayed(Duration.zero);

    expect(events.last.rewindSize, greaterThan(0));
  });

  test('rewind buffer stays empty when rewind is disabled', () async {
    final robot = RomRobot('../../roms/test/nestest/nestest.nes');
    final nes = robot.nes
      ..rewindEnabled = false
      ..fastForward = true;

    final events = await nes.eventBus.stream
        .where((event) => event is FrameNesEvent)
        .cast<FrameNesEvent>()
        .take(10)
        .toList()
        .timeout(const Duration(seconds: 60));

    nes.stop();

    await Future<void>.delayed(Duration.zero);

    expect(events.every((event) => event.rewindSize == 0), isTrue);
  });
}
