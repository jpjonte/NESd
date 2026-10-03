import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/mmc3_chr_ram.dart';

import 'mmc3_chr_ram_harness.dart';

void _selectChr(MMC3ChrRam mapper, int register, int bank) {
  mapper
    ..cpuWrite(0x8000, register)
    ..cpuWrite(0x8001, bank);
}

bool _isRam(MMC3ChrRam mapper, int bank) {
  _selectChr(mapper, 2, bank);

  final before = mapper.ppuRead(0x1000);

  mapper.ppuWrite(0x1000, before ^ 0xff);

  return mapper.ppuRead(0x1000) == before ^ 0xff;
}

void main() {
  group('header parsing', () {
    for (final (id, name, ramSize) in const [
      (74, 'Waixing MMC3 (74)', 0x800),
      (119, 'TQROM', 0x2000),
      (192, 'Waixing MMC3 (192)', 0x1000),
    ]) {
      test('mapper $id is $name with ${ramSize ~/ 0x400} KiB CHR-RAM', () {
        final mapper = buildMmc3ChrRam(id);

        expect(mapper.id, id);
        expect(mapper.name, name);
        expect(mapper.cartridge.chrRam.length, ramSize);
      });
    }
  });

  group('mapper 74', () {
    test('banks 8 and 9 are CHR-RAM', () {
      final mapper = buildMmc3ChrRam(74);

      expect(_isRam(mapper, 8), isTrue);
      expect(_isRam(mapper, 9), isTrue);
    });

    test('banks around 8 and 9 stay CHR-ROM', () {
      final mapper = buildMmc3ChrRam(74);

      expect(_isRam(mapper, 7), isFalse);
      expect(_isRam(mapper, 10), isFalse);

      _selectChr(mapper, 2, 10);

      expect(mapper.ppuRead(0x1000), 10);
    });

    test('banks 8 and 9 address separate 1 KiB halves', () {
      final mapper = buildMmc3ChrRam(74);

      _selectChr(mapper, 2, 8);
      mapper.ppuWrite(0x1000, 0x88);

      _selectChr(mapper, 2, 9);
      mapper.ppuWrite(0x1000, 0x99);

      _selectChr(mapper, 2, 8);

      expect(mapper.ppuRead(0x1000), 0x88);
    });

    test('a 2 KiB register selecting bank 8 maps RAM at both halves', () {
      final mapper = buildMmc3ChrRam(74);

      _selectChr(mapper, 0, 8);

      mapper
        ..ppuWrite(0x0000, 0x11)
        ..ppuWrite(0x0400, 0x22);

      expect(mapper.ppuRead(0x0000), 0x11);
      expect(mapper.ppuRead(0x0400), 0x22);
    });
  });

  group('mapper 119', () {
    test('bank bit 6 selects CHR-RAM', () {
      final mapper = buildMmc3ChrRam(119);

      expect(_isRam(mapper, 0x40), isTrue);
      expect(_isRam(mapper, 0x47), isTrue);
    });

    test('banks with bit 6 clear are CHR-ROM', () {
      final mapper = buildMmc3ChrRam(119);

      expect(_isRam(mapper, 0x05), isFalse);

      _selectChr(mapper, 2, 0x3f);

      expect(mapper.ppuRead(0x1000), 0x3f);
    });

    test('CHR-RAM banks wrap at 8 KiB', () {
      final mapper = buildMmc3ChrRam(119);

      _selectChr(mapper, 2, 0x41);
      mapper.ppuWrite(0x1000, 0x5a);

      _selectChr(mapper, 2, 0x49);

      expect(mapper.ppuRead(0x1000), 0x5a);
    });
  });

  group('mapper 192', () {
    test('banks 8 through 11 are CHR-RAM', () {
      final mapper = buildMmc3ChrRam(192);

      for (var bank = 8; bank <= 11; bank++) {
        expect(_isRam(mapper, bank), isTrue, reason: 'bank $bank');
      }
    });

    test('banks around 8 through 11 stay CHR-ROM', () {
      final mapper = buildMmc3ChrRam(192);

      expect(_isRam(mapper, 7), isFalse);
      expect(_isRam(mapper, 12), isFalse);
    });
  });

  group('state', () {
    test('restoring a state remaps CHR-RAM banks', () {
      final source = buildMmc3ChrRam(119);

      _selectChr(source, 2, 0x42);

      final target = buildMmc3ChrRam(119)
        ..state = source.state
        ..ppuWrite(0x1000, 0x77);

      expect(target.ppuRead(0x1000), 0x77);
    });
  });
}
