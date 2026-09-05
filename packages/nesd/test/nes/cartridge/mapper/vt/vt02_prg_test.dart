import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/vt/vt02.dart';

import 'vt02_harness.dart';

int _bankAt(VT02 mapper, int address) =>
    mapper.cpuRead(address) | (mapper.cpuRead(address + 1) << 8);

void main() {
  group('power-on', () {
    test(r'maps bank 0 at $8000 and $A000 and the last two banks at $C000 '
        r'and $E000', () {
      final (:nes, :mapper) = buildVt02();

      expect(_bankAt(mapper, 0x8000), 0);
      expect(_bankAt(mapper, 0xa000), 0);
      expect(_bankAt(mapper, 0xc000), vtPrgBanks * 2 - 2);
      expect(_bankAt(mapper, 0xe000), vtPrgBanks * 2 - 1);
    });

    test('fixes the end of the 512 KiB middle bank, not of the ROM', () {
      final (:nes, :mapper) = buildVt02(prgBanks: 256);

      expect(_bankAt(mapper, 0xc000), 0x3e);
      expect(_bankAt(mapper, 0xe000), 0x3f);
    });
  });

  group('inner bank registers', () {
    test(r'$4107 selects the bank at $8000 and $4108 the bank at $A000', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x4107, 5)
        ..cpuWrite(0x4108, 9);

      expect(_bankAt(mapper, 0x8000), 5);
      expect(_bankAt(mapper, 0xa000), 9);
    });

    test(r'$4109 is ignored at $C000 while $410B bit 6 is clear', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x4109, 3);

      expect(_bankAt(mapper, 0xc000), vtPrgBanks * 2 - 2);
    });

    test(r'$4109 selects the bank at $C000 while $410B bit 6 is set', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x410b, 0x40)
        ..cpuWrite(0x4109, 3);

      expect(_bankAt(mapper, 0xc000), 3);
    });
  });

  group(r'$4105 bit 6', () {
    test(r'swaps the $8000 and $C000 sources and leaves the others', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x4107, 5)
        ..cpuWrite(0x4108, 9)
        ..cpuWrite(0x4105, 0x40);

      expect(_bankAt(mapper, 0x8000), vtPrgBanks * 2 - 2);
      expect(_bankAt(mapper, 0xa000), 9);
      expect(_bankAt(mapper, 0xc000), 5);
      expect(_bankAt(mapper, 0xe000), vtPrgBanks * 2 - 1);
    });

    test(r'moves $4109 to $8000 while $410B bit 6 is set', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x4107, 5)
        ..cpuWrite(0x4109, 3)
        ..cpuWrite(0x410b, 0x40)
        ..cpuWrite(0x4105, 0x40);

      expect(_bankAt(mapper, 0x8000), 3);
      expect(_bankAt(mapper, 0xc000), 5);
    });
  });

  group(r'$410B bits 0-2', () {
    const innerMasks = [0x3f, 0x1f, 0x0f, 0x07, 0x03, 0x01, 0x00, 0xff];

    for (var mode = 0; mode < 8; mode++) {
      final innerMask = innerMasks[mode];
      final middleMask = ~innerMask & 0xff;

      test(
        'mode $mode keeps 0x${innerMask.toRadixString(16)} of the inner bank '
        r'and takes the rest from $410A',
        () {
          final (:nes, :mapper) = buildVt02(prgBanks: 256);

          nes.bus
            ..cpuWrite(0x4107, 0xa5)
            ..cpuWrite(0x410a, 0x5a)
            ..cpuWrite(0x410b, mode);

          expect(
            _bankAt(mapper, 0x8000),
            (0xa5 & innerMask) | (0x5a & middleMask),
          );
          expect(
            _bankAt(mapper, 0xe000),
            (0xff & innerMask) | (0x5a & middleMask),
            reason: 'fixed bank',
          );
        },
      );
    }
  });

  group(r'$4100', () {
    test('bits 4-7 select the 2 MiB outer bank', () {
      final (:nes, :mapper) = buildVt02(prgBanks: 256);

      nes.bus
        ..cpuWrite(0x4107, 5)
        ..cpuWrite(0x4100, 0x10);

      expect(_bankAt(mapper, 0x8000), 0x105);
      expect(_bankAt(mapper, 0xe000), 0x13f, reason: 'fixed bank');
    });

    test('bits 0-3 leave the PRG banks alone', () {
      final (:nes, :mapper) = buildVt02(prgBanks: 256);

      nes.bus
        ..cpuWrite(0x4107, 5)
        ..cpuWrite(0x4100, 0x0f);

      expect(_bankAt(mapper, 0x8000), 5);
    });
  });

  group('save state', () {
    test('restores the PRG windows', () {
      final (nes: sourceNes, mapper: source) = buildVt02();

      sourceNes.bus
        ..cpuWrite(0x4107, 5)
        ..cpuWrite(0x4108, 9);

      final target = buildVt02().mapper..state = source.state;

      expect(_bankAt(target, 0x8000), 5);
      expect(_bankAt(target, 0xa000), 9);
    });
  });
}
