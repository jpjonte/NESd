import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/exception/unsupported_mapper.dart';
import 'package:nesd/nes/cartridge/mapper/mapper176.dart';

import 'mapper176_harness.dart';

void main() {
  group('construction', () {
    test('submapper 2 is rejected', () {
      expect(() => Mapper176(2), throwsA(isA<UnsupportedMapper>()));
    });

    test('submapper 6 is rejected', () {
      expect(() => Mapper176(6), throwsA(isA<UnsupportedMapper>()));
    });

    test('submappers 0, 1, 3, 4 and 5 are accepted', () {
      for (final subMapper in const [0, 1, 3, 4, 5]) {
        expect(Mapper176(subMapper).subMapperId, subMapper);
      }
    });
  });

  group('harness header parsing', () {
    test('the harness header parses as mapper 176 with its submapper', () {
      for (final subMapper in const [0, 1, 3, 4, 5]) {
        final mapper = buildMapper176(subMapper: subMapper);

        expect(mapper.id, 176, reason: 'submapper $subMapper');
        expect(mapper.subMapperId, subMapper, reason: 'submapper $subMapper');
      }
    });
  });

  group('outer register decode', () {
    test(r'$5010 writes the mode register at solder pad 0', () {
      final mapper = buildMapper176()..cpuWrite(0x5010, 0x04);

      expect(mapper.mode, 0x04);
    });

    test(r'$5000 does not decode at solder pad 0', () {
      // The pad bit must be SET for a register to answer. Pad 0 uses A4, so
      // $5000 (A4 clear) is not a register address.
      final mapper = buildMapper176()..cpuWrite(0x5000, 0x04);

      expect(mapper.mode, 0);
    });

    test(r'$5011 and $5012 write the base registers', () {
      final mapper = buildMapper176()
        ..cpuWrite(0x5011, 0xff)
        ..cpuWrite(0x5012, 0xa5);

      expect(mapper.prgBaseLsb, 0x7f);
      expect(mapper.chrBaseLsb, 0xa5);
    });

    test(r'$5013 writes the extended mode register', () {
      final mapper = buildMapper176()..cpuWrite(0x5013, 0x02);

      expect(mapper.extendedRegister, 0x02);
    });

    test(r'the conventional $5FF0-$5FF3 addresses decode at pad 0', () {
      final mapper = buildMapper176()
        ..cpuWrite(0x5ff0, 0x21)
        ..cpuWrite(0x5ff1, 0x22)
        ..cpuWrite(0x5ff2, 0x23)
        ..cpuWrite(0x5ff3, 0x02);

      expect(mapper.mode, 0x21);
      expect(mapper.prgBaseLsb, 0x22);
      expect(mapper.chrBaseLsb, 0x23);
      expect(mapper.extendedRegister, 0x02);
    });

    test('the solder pad selects which address bit must be set', () {
      // Pad 1 uses A5, so $5020 decodes and $5010 does not.
      final mapper = Mapper176(0, solderPad: 1);

      expect(mapper.outerAddressMask, 0xf023);
    });

    test(r'writes below $4020 are not decoded', () {
      final mapper = buildMapper176()..cpuWrite(0x4000, 0x04);

      expect(mapper.mode, 0);
    });

    test(r'$9FFF is inert because the MMC3 mask is $E003', () {
      final mapper = buildMapper176()
        ..cpuWrite(0x8000, 6)
        ..cpuWrite(0x9fff, 0x3f);

      expect(mapper.banks[6], 0);
    });

    test(r'submapper 3 decodes $5xx5 and $5xx6 as the MSB registers', () {
      final mapper = buildMapper176(subMapper: 3)
        ..cpuWrite(0x5015, 0x1f)
        ..cpuWrite(0x5016, 0x2a);

      expect(mapper.prgBaseMsb, 0x0f);
      expect(mapper.chrBaseMsb, 0x0a);
    });

    test(r'other submappers alias $5015/$5016 to the LSB registers', () {
      final mapper = buildMapper176()
        ..cpuWrite(0x5015, 0x1f)
        ..cpuWrite(0x5016, 0x2a);

      expect(mapper.prgBaseLsb, 0x1f);
      expect(mapper.chrBaseLsb, 0x2a);
      expect(mapper.prgBaseMsb, 0);
      expect(mapper.chrBaseMsb, 0);
    });

    test(r'submapper 5 decodes $4800 as the PRG base MSB', () {
      final mapper = buildMapper176(subMapper: 5)..cpuWrite(0x4800, 0xff);

      expect(mapper.prgBaseMsb, 0x3f);
    });

    test(r'$4800 does not write prgBaseMsb outside submapper 5', () {
      final mapper = buildMapper176()..cpuWrite(0x4800, 0xff);

      expect(mapper.prgBaseMsb, 0);
    });
  });

  group('PRG banking, MMC3 modes', () {
    test('mode 0 on submapper 0 uses a 512 KiB outer bank', () {
      final mapper = buildMapper176()
        ..cpuWrite(0x5010, 0)
        ..cpuWrite(0x5011, 0x40)
        ..cpuWrite(0x8000, 6)
        ..cpuWrite(0x8001, 3)
        ..cpuWrite(0x8000, 7)
        ..cpuWrite(0x8001, 5);

      expect(mapper.cpuRead(0x8000), 0x80 | 3);
      expect(mapper.cpuRead(0xa000), 0x80 | 5);
      expect(mapper.cpuRead(0xc000), 0x80 | 0x3e);
      expect(mapper.cpuRead(0xe000), 0x80 | 0x3f);
    });

    test('modes 6 and 7 alias mode 0 on submapper 0', () {
      for (final mode in const [6, 7]) {
        final mapper = buildMapper176()
          ..cpuWrite(0x5010, mode)
          ..cpuWrite(0x5011, 0x40)
          ..cpuWrite(0x8000, 6)
          ..cpuWrite(0x8001, 3);

        expect(mapper.cpuRead(0x8000), 0x80 | 3, reason: 'mode $mode');
        expect(mapper.cpuRead(0xe000), 0x80 | 0x3f, reason: 'mode $mode');
      }
    });

    test('mode 1 uses a 256 KiB outer bank', () {
      final mapper = buildMapper176()
        ..cpuWrite(0x5010, 1)
        ..cpuWrite(0x5011, 0x40) // page base 0x80
        ..cpuWrite(0x8000, 6)
        ..cpuWrite(0x8001, 3);

      expect(mapper.cpuRead(0x8000), 0x80 | 3);
      expect(mapper.cpuRead(0xe000), 0x80 | 0x1f);
    });

    test('mode 2 uses a 128 KiB outer bank', () {
      final mapper = buildMapper176()
        ..cpuWrite(0x5010, 2)
        ..cpuWrite(0x5011, 0x48) // page base 0x90
        ..cpuWrite(0x8000, 6)
        ..cpuWrite(0x8001, 3);

      expect(mapper.cpuRead(0x8000), 0x90 | 3);
      expect(mapper.cpuRead(0xe000), 0x90 | 0x0f);
    });

    test('base bits below the outer window size are discarded', () {
      // $5xx1 = $44 -> page base $88. In mode 2 the MMC3 supplies page
      // bits 3-0, so the base's bit 3 is dropped by the hardware.
      final mapper = buildMapper176()
        ..cpuWrite(0x5010, 2)
        ..cpuWrite(0x5011, 0x44)
        ..cpuWrite(0x8000, 6)
        ..cpuWrite(0x8001, 3);

      expect(mapper.cpuRead(0x8000), 0x83);
    });

    test('mode 0 on submapper 1 addresses the full 2 MiB from MMC3', () {
      final mapper = buildMapper176(subMapper: 1)
        ..cpuWrite(0x5010, 0)
        ..cpuWrite(0x5011, 0x7f) // ignored: no base bits in this mode
        ..cpuWrite(0x8000, 6)
        ..cpuWrite(0x8001, 0xa3);

      expect(mapper.cpuRead(0x8000), 0xa3);
      expect(mapper.cpuRead(0xe000), 0xff);
    });
  });
}
