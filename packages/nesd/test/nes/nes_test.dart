import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../test_roms/rom_robot.dart';
import '../ui/mocks.dart';

class _ThrowingNes extends NES {
  _ThrowingNes({required super.cartridge, required super.eventBus});

  @override
  void step() => throw StateError('unexpected emulation error');
}

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

  test('run loop clears inLoop when an unexpected error escapes', () async {
    final rom = Uint8List(16 + 0x4000 + 0x2000)
      ..setAll(0, const [0x4e, 0x45, 0x53, 0x1a, 1, 1, 0, 0]);

    final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
      const FilesystemFile(
        path: 'nrom-test.nes',
        name: 'nrom-test.nes',
        type: FilesystemFileType.file,
      ),
      rom,
    )..databaseEntry = null;

    final nes = _ThrowingNes(cartridge: cartridge, eventBus: EventBus());

    await expectLater(nes.run(), throwsStateError);

    expect(nes.inLoop, isFalse);
  });
}
