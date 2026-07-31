import 'package:flutter_test/flutter_test.dart';

import '../../../test_roms/rom_robot.dart';

void main() {
  group(r'$4015 channel enable bits', () {
    late RomRobot robot;

    setUp(() async {
      robot = RomRobot('../../roms/test/nestest/nestest.nes');

      robot.nes.stop();

      await Future<void>.delayed(Duration.zero);
    });

    test('bit 0 enables pulse 1 only', () {
      final apu = robot.nes.apu..writeRegister(0x4015, 0x01);

      expect(apu.pulse1.enabled, true);
      expect(apu.pulse2.enabled, false);
    });

    test('bit 1 enables pulse 2 only', () {
      final apu = robot.nes.apu..writeRegister(0x4015, 0x02);

      expect(apu.pulse2.enabled, true);
      expect(apu.pulse1.enabled, false);
    });

    test('each channel reads its own bit', () {
      final apu = robot.nes.apu..writeRegister(0x4015, 0x1f);

      expect(apu.pulse1.enabled, true);
      expect(apu.pulse2.enabled, true);
      expect(apu.triangle.enabled, true);
      expect(apu.noise.enabled, true);
      expect(apu.dmc.enabled, true);
    });
  });
}
