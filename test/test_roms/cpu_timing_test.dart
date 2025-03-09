import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/bus.dart';

import 'rom_robot.dart';

void main() {
  test('Run CPU timing test', () {
    RomRobot('roms/test/cpu_timing_test6/cpu_timing_test.nes')
      ..buttonDown(0, NesButton.b) // start test of all opcodes
      ..runUntil(
        0xe1b7,
        maxCycles: 30000000,
        expect:
            (nes) => expect(
              nes.cpu.PC,
              isNot(equals(0xe116)),
            ), // E116 is the failure subroutine
      ); // run until all tests passed
  });
}
