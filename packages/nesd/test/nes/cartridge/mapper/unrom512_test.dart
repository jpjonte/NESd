import 'package:flutter_test/flutter_test.dart';

import 'unrom512_harness.dart';

void main() {
  group('harness header parsing', () {
    test('the harness header parses as mapper 30', () {
      final mapper = buildUnrom512();

      expect(mapper.id, 30);
    });

    test('the harness allocates 32 KiB of CHR-RAM', () {
      final mapper = buildUnrom512();

      expect(mapper.cartridge.chrRam.length, 0x8000);
    });

    test('a header declaring 8 KiB of CHR-RAM is widened to 32 KiB', () {
      final mapper = buildUnrom512(chrRamShift: 7);

      expect(mapper.cartridge.chrRam.length, 0x8000);
    });
  });

  group('register range', () {
    test('a flashable board does not latch writes below \$c000', () {
      final mapper = buildUnrom512(battery: true)..cpuWrite(0x9000, 0x05);

      expect(mapper.cpuRead(0x8000), 0);
    });

    test('a flashable board latches writes at \$c000 and above', () {
      final mapper = buildUnrom512(battery: true)..cpuWrite(0xc000, 0x05);

      expect(mapper.cpuRead(0x8000), 5);
    });

    test('submapper 1 does not latch writes below \$c000', () {
      final mapper = buildUnrom512(subMapper: 1)..cpuWrite(0x9000, 0x05);

      expect(mapper.cpuRead(0x8000), 0);
    });

    test('a bus-conflict board latches writes below \$c000', () {
      final mapper = buildUnrom512()
        ..cpuWrite(0xc000, 0x03) // bank 3, whose contents are $03
        ..cpuWrite(0x8000, 0x02);

      expect(mapper.cpuRead(0x8000), 2);
    });

    test('submapper 2 latches writes below \$c000', () {
      final mapper = buildUnrom512(subMapper: 2)
        ..cpuWrite(0xc000, 0x03)
        ..cpuWrite(0x8000, 0x02);

      expect(mapper.cpuRead(0x8000), 2);
    });
  });

  group('bus conflicts', () {
    test('submapper 0 without a battery masks writes with ROM contents', () {
      final mapper = buildUnrom512()
        ..cpuWrite(0xc000, 0x03) // bank 3, whose contents are $03
        ..cpuWrite(0x8000, 0x07);

      expect(mapper.cpuRead(0x8000), 3);
    });

    test('submapper 2 masks writes with ROM contents', () {
      final mapper = buildUnrom512(subMapper: 2)
        ..cpuWrite(0xc000, 0x03)
        ..cpuWrite(0x8000, 0x07);

      expect(mapper.cpuRead(0x8000), 3);
    });

    test('a bus conflict also masks the CHR bank bits', () {
      final mapper = buildUnrom512()
        ..ppuWrite(0x0000, 0x42)
        ..cpuWrite(0xc000, 0x60);

      expect(mapper.ppuRead(0x0000), 0x42);
    });

    test('a flashable board applies the CHR bank bits unmasked', () {
      final mapper = buildUnrom512(battery: true)
        ..ppuWrite(0x0000, 0x42)
        ..cpuWrite(0xc000, 0x60);

      expect(mapper.ppuRead(0x0000), 0);
    });

    test('submapper 1 applies the CHR bank bits unmasked', () {
      final mapper = buildUnrom512(subMapper: 1)
        ..ppuWrite(0x0000, 0x42)
        ..cpuWrite(0xc000, 0x60);

      expect(mapper.ppuRead(0x0000), 0);
    });
  });

  group('PRG banking', () {
    test('the switchable window selects the latched bank', () {
      final mapper = buildUnrom512(battery: true)..cpuWrite(0xc000, 5);

      expect(mapper.cpuRead(0x8000), 5);
    });

    test('the switchable window starts on bank 0', () {
      final mapper = buildUnrom512(battery: true);

      expect(mapper.cpuRead(0x8000), 0);
    });

    test('the fixed window always reads the last bank', () {
      final mapper = buildUnrom512(battery: true)..cpuWrite(0xc000, 5);

      expect(mapper.cpuRead(0xc000), unrom512PrgBanks - 1);
    });

    test('only the low five bits select the PRG bank', () {
      final mapper = buildUnrom512(battery: true)..cpuWrite(0xc000, 0xe9);

      expect(mapper.cpuRead(0x8000), 9);
    });
  });

  group('CHR-RAM banking', () {
    test('a CHR bank selection isolates the banks', () {
      final mapper = buildUnrom512(battery: true)
        ..ppuWrite(0x0000, 0x42)
        ..cpuWrite(0xc000, 0x20); // CHR bank 1

      expect(mapper.ppuRead(0x0000), 0);
    });

    test('switching back to a CHR bank restores its contents', () {
      final mapper = buildUnrom512(battery: true)
        ..ppuWrite(0x0000, 0x42)
        ..cpuWrite(0xc000, 0x20) // CHR bank 1
        ..cpuWrite(0xc000, 0x00); // CHR bank 0

      expect(mapper.ppuRead(0x0000), 0x42);
    });

    test('all four CHR banks are distinct', () {
      final mapper = buildUnrom512(battery: true);

      for (var bank = 0; bank < 4; bank++) {
        mapper
          ..cpuWrite(0xc000, bank << 5)
          ..ppuWrite(0x0000, 0xa0 | bank);
      }

      for (var bank = 0; bank < 4; bank++) {
        mapper.cpuWrite(0xc000, bank << 5);

        expect(mapper.ppuRead(0x0000), 0xa0 | bank);
      }
    });
  });

  group('mirroring', () {
    test('a header without the four-screen bit gives vertical arrangement', () {
      final mapper = buildUnrom512(battery: true)..ppuWrite(0x2000, 0x11);

      expect(mapper.ppuRead(0x2400), 0x11);
      expect(mapper.ppuRead(0x2800), isNot(0x11));
    });

    test('a header with bit 0 set gives horizontal arrangement', () {
      final mapper = buildUnrom512(battery: true, horizontalArrangement: true)
        ..ppuWrite(0x2000, 0x11);

      expect(mapper.ppuRead(0x2800), 0x11);
      expect(mapper.ppuRead(0x2400), isNot(0x11));
    });

    test('fixed mirroring ignores bit 7 of the latch', () {
      final mapper = buildUnrom512(battery: true)
        ..ppuWrite(0x2000, 0x11)
        ..cpuWrite(0xc000, 0x80);

      expect(mapper.ppuRead(0x2400), 0x11);
      expect(mapper.ppuRead(0x2800), isNot(0x11));
    });

    test('the four-screen bit selects one-screen mirroring', () {
      final mapper = buildUnrom512(battery: true, fourScreen: true)
        ..ppuWrite(0x2000, 0x11);

      expect(mapper.ppuRead(0x2400), 0x11);
      expect(mapper.ppuRead(0x2800), 0x11);
      expect(mapper.ppuRead(0x2c00), 0x11);
    });

    test('bit 7 clear selects the lower one-screen page', () {
      final mapper = buildUnrom512(battery: true, fourScreen: true)
        ..cpuWrite(0xc000, 0x80)
        ..ppuWrite(0x2000, 0x22)
        ..cpuWrite(0xc000, 0x00)
        ..ppuWrite(0x2000, 0x11);

      expect(mapper.ppuRead(0x2000), 0x11);
    });

    test('bit 7 set selects the upper one-screen page', () {
      final mapper = buildUnrom512(battery: true, fourScreen: true)
        ..cpuWrite(0xc000, 0x00)
        ..ppuWrite(0x2000, 0x11)
        ..cpuWrite(0xc000, 0x80);

      expect(mapper.ppuRead(0x2000), isNot(0x11));
    });

    test('the one-screen page switch preserves both pages', () {
      final mapper = buildUnrom512(battery: true, fourScreen: true)
        ..cpuWrite(0xc000, 0x00)
        ..ppuWrite(0x2000, 0x11)
        ..cpuWrite(0xc000, 0x80)
        ..ppuWrite(0x2000, 0x22)
        ..cpuWrite(0xc000, 0x00);

      expect(mapper.ppuRead(0x2000), 0x11);
    });

    test('submapper 3 selects vertical arrangement with bit 7 clear', () {
      final mapper = buildUnrom512(subMapper: 3)
        ..cpuWrite(0xc000, 0x00)
        ..ppuWrite(0x2000, 0x11);

      expect(mapper.ppuRead(0x2400), 0x11);
      expect(mapper.ppuRead(0x2800), isNot(0x11));
    });

    test('submapper 3 selects horizontal arrangement with bit 7 set', () {
      final mapper = buildUnrom512(subMapper: 3)
        ..cpuWrite(0xc000, 0x00)
        ..ppuWrite(0x2000, 0x11)
        ..cpuWrite(0xc000, 0x80);

      expect(mapper.ppuRead(0x2800), 0x11);
      expect(mapper.ppuRead(0x2400), isNot(0x11));
    });

    test('a four-screen header falls back to the header arrangement', () {
      final mapper = buildUnrom512(
        battery: true,
        fourScreen: true,
        horizontalArrangement: true,
      )..ppuWrite(0x2000, 0x11);

      expect(mapper.ppuRead(0x2800), 0x11);
      expect(mapper.ppuRead(0x2400), isNot(0x11));
    });
  });

  group('save states', () {
    test('a save state restores the latch', () {
      final mapper = buildUnrom512(battery: true)..cpuWrite(0xc000, 0x09);

      final state = mapper.state;

      mapper
        ..cpuWrite(0xc000, 0x11)
        ..state = state;

      expect(mapper.cpuRead(0x8000), 9);
    });
  });
}
