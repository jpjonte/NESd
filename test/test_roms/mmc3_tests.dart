import 'package:flutter_test/flutter_test.dart';

import 'rom_robot.dart';

void main() {
  test('MMC3 IRQ timing', () {
    RomRobot('roms/test/mmc3_irq_tests/1.Clocking.nes').runUntil(
      0xe08b,
      maxCycles: 700000,
      expect: (nes) {
        expect(
          nes.cpu.PC,
          isNot(equals(0xe045)),
        ); // e045 is the failure subroutine
      },
    ); // run until all tests passed
  });
}
