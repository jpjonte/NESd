import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/vt/vt02.dart';

import 'vt02_harness.dart';

int _bankAt(VT02 mapper, int address) =>
    mapper.ppuRead(address) | (mapper.ppuRead(address + 1) << 8);

int _prgBankAt(VT02 mapper, int address) =>
    mapper.cpuRead(address) | (mapper.cpuRead(address + 1) << 8);

void main() {
  group('submapper 1 (Waixing VT03)', () {
    test(r'native $2012-$2017 writes drive the scrambled CHR windows', () {
      final (:nes, :mapper) = buildVt02(subMapperId: 1);

      nes.bus
        ..cpuWrite(0x2012, 0x10)
        ..cpuWrite(0x2013, 0x11)
        ..cpuWrite(0x2014, 0x12)
        ..cpuWrite(0x2015, 0x14)
        ..cpuWrite(0x2016, 0x16)
        ..cpuWrite(0x2017, 0x17);

      expect(_bankAt(mapper, 0x1400), 0x10, reason: r'$2012');
      expect(_bankAt(mapper, 0x1000), 0x11, reason: r'$2013');
      expect(_bankAt(mapper, 0x0800), 0x12, reason: r'$2014');
      expect(_bankAt(mapper, 0x0c00), 0x13, reason: r'$2014 odd bank');
      expect(_bankAt(mapper, 0x0000), 0x14, reason: r'$2015');
      expect(_bankAt(mapper, 0x0400), 0x15, reason: r'$2015 odd bank');
      expect(_bankAt(mapper, 0x1c00), 0x16, reason: r'$2016');
      expect(_bankAt(mapper, 0x1800), 0x17, reason: r'$2017');
    });

    test(r'forwarded $8000.0-$8000.5 drive the scrambled CHR windows', () {
      final (:nes, :mapper) = buildVt02(subMapperId: 1);

      for (final (register, value) in [
        (0, 0x16),
        (1, 0x17),
        (2, 0x11),
        (3, 0x10),
        (4, 0x12),
        (5, 0x14),
      ]) {
        nes.bus
          ..cpuWrite(0x8000, register)
          ..cpuWrite(0x8001, value);
      }

      expect(_bankAt(mapper, 0x1c00), 0x16, reason: 'R0');
      expect(_bankAt(mapper, 0x1800), 0x17, reason: 'R1');
      expect(_bankAt(mapper, 0x1400), 0x11, reason: 'R2');
      expect(_bankAt(mapper, 0x1000), 0x10, reason: 'R3');
      expect(_bankAt(mapper, 0x0800), 0x12, reason: 'R4');
      expect(_bankAt(mapper, 0x0c00), 0x13, reason: 'R4 odd bank');
      expect(_bankAt(mapper, 0x0000), 0x14, reason: 'R5');
      expect(_bankAt(mapper, 0x0400), 0x15, reason: 'R5 odd bank');
    });
  });

  group('submapper 3 (Zechess/Hummer Team)', () {
    test(r'native $2012-$2017 writes drive the scrambled CHR windows', () {
      final (:nes, :mapper) = buildVt02(subMapperId: 3);

      nes.bus
        ..cpuWrite(0x2012, 0x12)
        ..cpuWrite(0x2013, 0x14)
        ..cpuWrite(0x2014, 0x16)
        ..cpuWrite(0x2015, 0x17)
        ..cpuWrite(0x2016, 0x10)
        ..cpuWrite(0x2017, 0x11);

      expect(_bankAt(mapper, 0x0800), 0x12, reason: r'$2012');
      expect(_bankAt(mapper, 0x0c00), 0x13, reason: r'$2012 odd bank');
      expect(_bankAt(mapper, 0x0000), 0x14, reason: r'$2013');
      expect(_bankAt(mapper, 0x0400), 0x15, reason: r'$2013 odd bank');
      expect(_bankAt(mapper, 0x1c00), 0x16, reason: r'$2014');
      expect(_bankAt(mapper, 0x1800), 0x17, reason: r'$2015');
      expect(_bankAt(mapper, 0x1000), 0x10, reason: r'$2016');
      expect(_bankAt(mapper, 0x1400), 0x11, reason: r'$2017');
    });

    test(r'forwarded $8000.0-$8000.5 drive the normal CHR windows', () {
      final (:nes, :mapper) = buildVt02(subMapperId: 3);

      for (final (register, value) in [
        (0, 0x14),
        (1, 0x12),
        (2, 0x10),
        (3, 0x11),
        (4, 0x16),
        (5, 0x17),
      ]) {
        nes.bus
          ..cpuWrite(0x8000, register)
          ..cpuWrite(0x8001, value);
      }

      expect(_bankAt(mapper, 0x0000), 0x14, reason: 'R0');
      expect(_bankAt(mapper, 0x0400), 0x15, reason: 'R0 odd bank');
      expect(_bankAt(mapper, 0x0800), 0x12, reason: 'R1');
      expect(_bankAt(mapper, 0x0c00), 0x13, reason: 'R1 odd bank');
      expect(_bankAt(mapper, 0x1000), 0x10, reason: 'R2');
      expect(_bankAt(mapper, 0x1400), 0x11, reason: 'R3');
      expect(_bankAt(mapper, 0x1800), 0x16, reason: 'R4');
      expect(_bankAt(mapper, 0x1c00), 0x17, reason: 'R5');
    });
  });

  group('submapper 4 (Qishenglong)', () {
    test(r'native $2012-$2017 writes drive the scrambled CHR windows', () {
      final (:nes, :mapper) = buildVt02(subMapperId: 4);

      nes.bus
        ..cpuWrite(0x2012, 0x16)
        ..cpuWrite(0x2013, 0x12)
        ..cpuWrite(0x2014, 0x10)
        ..cpuWrite(0x2015, 0x14)
        ..cpuWrite(0x2016, 0x17)
        ..cpuWrite(0x2017, 0x11);

      expect(_bankAt(mapper, 0x1800), 0x16, reason: r'$2012');
      expect(_bankAt(mapper, 0x0800), 0x12, reason: r'$2013');
      expect(_bankAt(mapper, 0x0c00), 0x13, reason: r'$2013 odd bank');
      expect(_bankAt(mapper, 0x1000), 0x10, reason: r'$2014');
      expect(_bankAt(mapper, 0x0000), 0x14, reason: r'$2015');
      expect(_bankAt(mapper, 0x0400), 0x15, reason: r'$2015 odd bank');
      expect(_bankAt(mapper, 0x1c00), 0x17, reason: r'$2016');
      expect(_bankAt(mapper, 0x1400), 0x11, reason: r'$2017');
    });
  });

  group('submapper 5 (Waixing VT02)', () {
    test(r'native $2012-$2017 writes drive the scrambled CHR windows', () {
      final (:nes, :mapper) = buildVt02(subMapperId: 5);

      nes.bus
        ..cpuWrite(0x2012, 0x10)
        ..cpuWrite(0x2013, 0x11)
        ..cpuWrite(0x2014, 0x12)
        ..cpuWrite(0x2015, 0x14)
        ..cpuWrite(0x2016, 0x16)
        ..cpuWrite(0x2017, 0x18);

      expect(_bankAt(mapper, 0x1400), 0x10, reason: r'$2012');
      expect(_bankAt(mapper, 0x1000), 0x11, reason: r'$2013');
      expect(_bankAt(mapper, 0x0000), 0x16, reason: r'$2016 after $2015');
      expect(_bankAt(mapper, 0x0400), 0x17, reason: r'$2016 odd bank');
      expect(_bankAt(mapper, 0x0800), 0x18, reason: r'$2017 after $2014');
      expect(_bankAt(mapper, 0x0c00), 0x19, reason: r'$2017 odd bank');
      expect(_bankAt(mapper, 0x1800), 0, reason: 'no register drives it');
      expect(_bankAt(mapper, 0x1c00), 0, reason: 'no register drives it');
    });
  });

  group('submapper 2 (Power Joy Supermax)', () {
    test(r'native $4107 and $4108 drive the swapped CPU windows', () {
      final (:nes, :mapper) = buildVt02(subMapperId: 2);

      nes.bus
        ..cpuWrite(0x4107, 3)
        ..cpuWrite(0x4108, 5);

      expect(_prgBankAt(mapper, 0xa000), 3, reason: r'$4107');
      expect(_prgBankAt(mapper, 0x8000), 5, reason: r'$4108');
    });

    test(r'forwarded $8000.6 and $8000.7 drive the swapped CPU windows', () {
      final (:nes, :mapper) = buildVt02(subMapperId: 2);

      nes.bus
        ..cpuWrite(0x8000, 6)
        ..cpuWrite(0x8001, 3)
        ..cpuWrite(0x8000, 7)
        ..cpuWrite(0x8001, 5);

      expect(_prgBankAt(mapper, 0xa000), 3, reason: r'$8000.6');
      expect(_prgBankAt(mapper, 0x8000), 5, reason: r'$8000.7');
    });
  });

  group('unknown submappers', () {
    test('fall back to the normal register layout', () {
      final (:nes, :mapper) = buildVt02(subMapperId: 11);

      nes.bus
        ..cpuWrite(0x2012, 0x10)
        ..cpuWrite(0x4107, 3);

      expect(_bankAt(mapper, 0x1000), 0x10);
      expect(_prgBankAt(mapper, 0x8000), 3);
    });
  });

  group('save state', () {
    test('scrambled registers survive a state copy', () {
      final (nes: sourceNes, mapper: source) = buildVt02(subMapperId: 3);

      sourceNes.bus
        ..cpuWrite(0x2016, 0x10)
        ..cpuWrite(0x2012, 0x12);

      final target = buildVt02(subMapperId: 3).mapper..state = source.state;

      expect(_bankAt(target, 0x1000), 0x10);
      expect(_bankAt(target, 0x0800), 0x12);
    });
  });
}
