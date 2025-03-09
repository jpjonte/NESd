import 'package:flutter_test/flutter_test.dart';

import 'rom_robot.dart';

void main() {
  test('Run blargg CPU test', () {
    RomRobot('roms/test/blargg_nes_cpu_test5/cpu.nes').runUntil(
      0x854b,
      maxCycles: 30000000,
      expect: (nes) {
        expect(
          nes.cpu.PC,
          isNot(equals(0x8530)),
        ); // 8530 is the failure subroutine
      },
    ); // run until all tests passed
  });
}
