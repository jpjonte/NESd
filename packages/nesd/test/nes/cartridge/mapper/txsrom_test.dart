import 'package:flutter_test/flutter_test.dart';

import 'txsrom_harness.dart';

void main() {
  group('harness header parsing', () {
    test('the harness header parses as mapper 118', () {
      final mapper = buildTxsrom();

      expect(mapper.id, 118);
    });
  });

  group('PRG banking', () {
    test('a PRG bank selection resolves correctly', () {
      final mapper = buildTxsrom()
        ..cpuWrite(0x8000, 6)
        ..cpuWrite(0x8001, 5);

      expect(mapper.cpuRead(0x8000), 5);
    });
  });

  group('CHR banking', () {
    test('a CHR bank selection resolves correctly', () {
      final mapper = buildTxsrom()
        ..cpuWrite(0x8000, 2)
        ..cpuWrite(0x8001, 30);

      expect(mapper.ppuRead(0x1000), 30);
    });
  });

  // TxSROM replaces the $A000 mirroring register, with a per-bank nametable
  // select hidden in $8001 bit 7.
  // These tests use reset() explicitly to seed the initial nametable mapping.
  group('nametable select', () {
    test(r'$8001 bit 7 moves nametables 0 and 1 together in chrBankMode 0', () {
      final mapper = buildTxsrom()
        ..reset()
        ..cpuWrite(0x8000, 0) // select register 0, chrBankMode 0
        ..cpuWrite(0x8001, 0x00) // nametable bit 7 = 0 -> page 0
        ..ppuWrite(0x2000, 0x11); // logical nametable 0, page 0

      expect(mapper.ppuRead(0x2400), 0x11);
    });

    test(r'$8001 bit 7 moves a single nametable in chrBankMode 1', () {
      final mapper = buildTxsrom()
        ..reset()
        ..cpuWrite(0x8000, 0x80 | 2) // select register 2, chrBankMode 1
        ..cpuWrite(0x8001, 0x80) // nametable bit 7 = 1 -> page 1
        ..ppuWrite(0x2400, 0x22); // logical nametable 1, page 1 (default)

      expect(mapper.ppuRead(0x2000), 0x22);

      mapper
        ..cpuWrite(0x8000, 0x80 | 2) // select register 2, chrBankMode 1
        ..cpuWrite(0x8001, 0x00) // nametable bit 7 = 0 -> page 0
        ..ppuWrite(0x2800, 0x33); // logical nametable 2, page 0 (default)

      expect(mapper.ppuRead(0x2000), 0x33);
    });
  });
}
