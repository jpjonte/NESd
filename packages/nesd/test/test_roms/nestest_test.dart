import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/nes.dart';

import 'rom_robot.dart';

void main() {
  test('Run nestest', () {
    void expectation(NES nes) {
      final low = nes.cpu.read(0x02);
      final high = nes.cpu.read(0x03);

      expect(low, equals(0));
      expect(high, equals(0));
    }

    RomRobot('../../roms/test/nestest/nestest.nes')
      ..buttonDown(0, NesButton.start) // start tests of official opcodes
      ..runUntil(
        0xc0ea,
        maxCycles: 600000,
        expect: expectation,
      ) // run until all tests passed
      ..buttonUp(0, NesButton.start)
      ..buttonDown(0, NesButton.select) // switch to next page
      ..runUntil(
        0xc135,
        maxCycles: 60000,
        expect: expectation,
      ) // run until page has been switched
      ..buttonUp(0, NesButton.select)
      ..buttonDown(0, NesButton.start) // start tests of unofficial opcodes
      ..runUntil(
        0xc18f,
        maxCycles: 400000,
        expect: expectation,
      ); // run until all tests passed
  });
}
