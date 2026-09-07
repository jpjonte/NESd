import 'package:flutter_test/flutter_test.dart';

import 'rom_robot.dart';

void main() {
  group('RomResult.tryFromScreen', () {
    test('reads PASSED as status 0', () {
      final result = RomResult.tryFromScreen('SPRITE HIT BASICS\nPASSED');

      expect(result?.status, 0);
      expect(result?.passed, isTrue);
    });

    test('accepts a trailing period and mixed case', () {
      expect(RomResult.tryFromScreen('PPU FRAME BASICS\nPASSED.')?.status, 0);
      expect(RomResult.tryFromScreen('cpu_dummy_reads\nPassed')?.status, 0);
    });

    test('reads the failure number after FAILED', () {
      expect(RomResult.tryFromScreen('MMC3 IRQ COUNTER\nFAILED #3')?.status, 3);
      expect(RomResult.tryFromScreen('OVERFLOW BASICS\nFAILED: #6')?.status, 6);
    });

    test('reads a bare FAILED as status 1', () {
      expect(RomResult.tryFromScreen('SOMETHING\nFAILED')?.status, 1);
    });

    test('reads a 2005-era hex code, where \$01 is a pass', () {
      expect(RomResult.tryFromScreen(r'$01')?.status, 0);
      expect(RomResult.tryFromScreen('TITLE\n\$02')?.status, 2);
      expect(RomResult.tryFromScreen(r'$0A')?.status, 10);
    });

    test('only takes a hex code that stands alone on its line', () {
      expect(RomResult.tryFromScreen(r'11 22 $01 33'), isNull);
      expect(RomResult.tryFromScreen(r'$01 done'), isNull);
    });

    test('returns null while no verdict is on screen', () {
      expect(RomResult.tryFromScreen('MMC3 IRQ COUNTER'), isNull);
      expect(RomResult.tryFromScreen(''), isNull);
    });

    test('keeps the screen text with whitespace collapsed', () {
      expect(RomResult.tryFromScreen('TITLE\n  PASSED')?.text, 'TITLE PASSED');
    });
  });

  group('RomRobot.crcOnScreen', () {
    test('finds an eight-digit hex CRC standing alone on a line', () {
      expect(RomRobot.crcOnScreen('11 22 11 22\n498C5C5F\n'), '498C5C5F');
    });

    test('ignores hex-looking values that share a line', () {
      expect(RomRobot.crcOnScreen('11 22 33 44 55 66 77 88'), isNull);
      expect(RomRobot.crcOnScreen('crc 498C5C5F'), isNull);
    });

    test('returns null while no CRC is on screen', () {
      expect(RomRobot.crcOnScreen('11 22\n'), isNull);
    });
  });
}
