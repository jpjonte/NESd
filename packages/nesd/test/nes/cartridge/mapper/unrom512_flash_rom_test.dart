import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/unrom512.dart';

import '../../../test_roms/rom_robot.dart';

/// Built by tool/build_unrom512_test_rom.dart.
const _rom = '../../roms/test/unrom512_flash/unrom512_flash.nes';

int _counter(RomRobot robot) => robot.nes.bus.cartridge.prgRom[0];

void _boot(RomRobot robot) => robot.runFrames(10);

void main() {
  group('UNROM 512 flash test ROM', () {
    test('loads as a battery-backed mapper 30 cartridge', () {
      final cartridge = RomRobot(_rom).nes.bus.cartridge;

      expect(cartridge.mapper, isA<UNROM512>());
      expect(cartridge.mapper.id, 30);
      expect(cartridge.hasBattery, isTrue);
      expect(cartridge.prgRom, hasLength(0x8000));
    });

    test('starts with an unwritten counter', () {
      expect(_counter(RomRobot(_rom)), 0);
    });

    test('erases and programs a sector on its first boot', () {
      final robot = RomRobot(_rom);
      final mapper = robot.nes.bus.cartridge.mapper as UNROM512;

      _boot(robot);

      expect(mapper.state.flashSectors.keys, [0]);
      expect(_counter(robot), 1);
    });

    test('increments its counter on every power cycle', () {
      final robot = RomRobot(_rom);
      final counters = <int>[];

      for (var boot = 0; boot < 4; boot++) {
        _boot(robot);

        counters.add(_counter(robot));

        robot.nes.reset();
      }

      expect(counters, [1, 2, 3, 4]);
    });

    test('carries its counter through a battery file', () {
      final source = RomRobot(_rom);

      _boot(source);
      source.nes.reset();
      _boot(source);

      expect(_counter(source), 2);

      final save = source.nes.bus.cartridge.save();

      expect(save, isNotNull);

      final restored = RomRobot(_rom);

      restored.nes.bus.cartridge.load(save!);

      expect(_counter(restored), 2);

      _boot(restored);

      expect(_counter(restored), 3);
    });

    test('a fresh cartridge does not inherit the counter', () {
      final source = RomRobot(_rom);

      _boot(source);

      expect(_counter(source), 1);
      expect(_counter(RomRobot(_rom)), 0);
    });

    test('rewinding past a flash write undoes it', () {
      final robot = RomRobot(_rom);
      final mapper = robot.nes.bus.cartridge.mapper as UNROM512;

      _boot(robot);

      final afterFirstBoot = mapper.state;

      expect(_counter(robot), 1);

      robot.nes.reset();
      _boot(robot);

      expect(_counter(robot), 2);

      mapper.state = afterFirstBoot;

      expect(_counter(robot), 1);
    });
  });
}
