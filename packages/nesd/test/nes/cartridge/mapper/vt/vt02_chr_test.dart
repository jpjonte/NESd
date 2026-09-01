import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/vt/vt02.dart';

import 'vt02_harness.dart';

int _bankAt(VT02 mapper, int address) =>
    mapper.ppuRead(address) | (mapper.ppuRead(address + 1) << 8);

void main() {
  group('power-on', () {
    test(r'maps banks 0 and 1 twice below $1000 and bank 0 above', () {
      final (:nes, :mapper) = buildVt02();

      expect(_bankAt(mapper, 0x0000), 0);
      expect(_bankAt(mapper, 0x0400), 1);
      expect(_bankAt(mapper, 0x0800), 0);
      expect(_bankAt(mapper, 0x0c00), 1);

      for (var slot = 4; slot < 8; slot++) {
        expect(_bankAt(mapper, slot * 0x400), 0, reason: 'slot $slot');
      }
    });
  });

  group('inner bank registers', () {
    test(r'$2016 selects the 2 KiB pair at $0000 and ignores bit 0', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x2016, 5);

      expect(_bankAt(mapper, 0x0000), 4);
      expect(_bankAt(mapper, 0x0400), 5);
    });

    test(r'$2017 selects the 2 KiB pair at $0800 and ignores bit 0', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x2017, 6);

      expect(_bankAt(mapper, 0x0800), 6);
      expect(_bankAt(mapper, 0x0c00), 7);
    });

    test(r'$2012-$2015 select the 1 KiB banks at $1000-$1FFF', () {
      final (:nes, :mapper) = buildVt02();

      for (var i = 0; i < 4; i++) {
        nes.bus.cpuWrite(0x2012 + i, 0x10 + i);
      }

      for (var i = 0; i < 4; i++) {
        expect(_bankAt(mapper, 0x1000 + i * 0x400), 0x10 + i, reason: 'RV$i');
      }
    });
  });

  group(r'$4105 bit 7', () {
    test('swaps the two pattern tables', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x2016, 4)
        ..cpuWrite(0x2017, 6)
        ..cpuWrite(0x2012, 0x10)
        ..cpuWrite(0x2013, 0x11)
        ..cpuWrite(0x2014, 0x12)
        ..cpuWrite(0x2015, 0x13)
        ..cpuWrite(0x4105, 0x80);

      expect(_bankAt(mapper, 0x0000), 0x10);
      expect(_bankAt(mapper, 0x0400), 0x11);
      expect(_bankAt(mapper, 0x0800), 0x12);
      expect(_bankAt(mapper, 0x0c00), 0x13);
      expect(_bankAt(mapper, 0x1000), 4);
      expect(_bankAt(mapper, 0x1400), 5);
      expect(_bankAt(mapper, 0x1800), 6);
      expect(_bankAt(mapper, 0x1c00), 7);
    });
  });

  group(r'$201A bits 0-2', () {
    const innerMasks = [0xff, 0x7f, 0x3f, 0xff, 0x1f, 0x0f, 0x07, 0xff];

    for (var mode = 0; mode < 8; mode++) {
      final innerMask = innerMasks[mode];
      final middleMask = ~innerMask & 0xff;

      test(
        'mode $mode keeps 0x${innerMask.toRadixString(16)} of the inner bank '
        r'and takes the rest from $201A bits 3-7',
        () {
          final (:nes, :mapper) = buildVt02(chrPages: 512);

          nes.bus
            ..cpuWrite(0x2012, 0x25)
            ..cpuWrite(0x201a, 0xd8 | mode);

          expect(
            _bankAt(mapper, 0x1000),
            (0x25 & innerMask) | (0xd8 & middleMask),
          );
        },
      );
    }
  });

  group(r'$2018', () {
    test('bits 4-6 select the 256 KiB intermediate bank', () {
      final (:nes, :mapper) = buildVt02(chrPages: 512);

      nes.bus
        ..cpuWrite(0x2012, 5)
        ..cpuWrite(0x2018, 0x70);

      expect(_bankAt(mapper, 0x1000), 0x705);
    });

    test('bits 0-3 leave the CHR banks alone', () {
      final (:nes, :mapper) = buildVt02(chrPages: 512);

      nes.bus
        ..cpuWrite(0x2012, 5)
        ..cpuWrite(0x2018, 0x0f);

      expect(_bankAt(mapper, 0x1000), 5);
    });

    test('bit 7 leaves the CHR banks alone', () {
      final (:nes, :mapper) = buildVt02(chrPages: 512);

      nes.bus
        ..cpuWrite(0x2012, 5)
        ..cpuWrite(0x2018, 0x80);

      expect(_bankAt(mapper, 0x1000), 5);
    });
  });

  group(r'$4100', () {
    test('bits 0-3 select the 2 MiB outer bank', () {
      final (:nes, :mapper) = buildVt02(chrPages: 512);

      nes.bus
        ..cpuWrite(0x2012, 5)
        ..cpuWrite(0x4100, 0x01);

      expect(_bankAt(mapper, 0x1000), 0x805);
    });

    test('bits 4-7 leave the CHR banks alone', () {
      final (:nes, :mapper) = buildVt02(chrPages: 512);

      nes.bus
        ..cpuWrite(0x2012, 5)
        ..cpuWrite(0x4100, 0xf0);

      expect(_bankAt(mapper, 0x1000), 5);
    });
  });

  group('OneBus images', () {
    test('read pattern data from the PRG-ROM when there is no CHR-ROM', () {
      final (:nes, :mapper) = buildVt02(chrPages: 0);

      nes.bus.cpuWrite(0x2012, 16);

      expect(_bankAt(mapper, 0x1000), 2, reason: '8 KiB PRG bank 2');
    });
  });

  group('save state', () {
    test('restores the CHR windows', () {
      final (nes: sourceNes, mapper: source) = buildVt02();

      sourceNes.bus
        ..cpuWrite(0x2012, 0x10)
        ..cpuWrite(0x2016, 4);

      final target = buildVt02().mapper..state = source.state;

      expect(_bankAt(target, 0x1000), 0x10);
      expect(_bankAt(target, 0x0000), 4);
    });
  });
}
