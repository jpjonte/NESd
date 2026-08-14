import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/mapper45.dart';

import 'mapper45_harness.dart';

void writeOuter(Mapper45 mapper, List<int> values) {
  for (final value in values) {
    mapper.cpuWrite(0x6000, value);
  }
}

Mapper45 withInnerBanks(Mapper45 mapper, List<int> values) {
  for (var register = 0; register < 8; register++) {
    mapper
      ..cpuWrite(0x8000, register)
      ..cpuWrite(0x8001, values[register]);
  }

  return mapper;
}

void main() {
  group('construction', () {
    test('the harness ROM resolves to mapper 45', () {
      final mapper = buildMapper45();

      expect(mapper.id, 45);
      expect(mapper.name, 'GA23C');
    });
  });

  group('power-on state', () {
    test('outer registers are zero and unlocked', () {
      final mapper = buildMapper45();

      expect(mapper.outerRegisters, [0, 0, 0, 0]);
      expect(mapper.writeIndex, 0);
      expect(mapper.prgAnd, 0x3f);
      expect(mapper.prgOr, 0);
      expect(mapper.chrAnd, 0);
      expect(mapper.chrOr, 0);
    });

    test('PRG is limited to the first 512 KiB', () {
      final mapper = buildMapper45();

      expect(mapper.cpuRead(0x8000), 0);
      expect(mapper.cpuRead(0xc000), 0x3e);
      expect(mapper.cpuRead(0xe000), 0x3f);
    });

    test('CHR is pinned to page 0 regardless of the MMC3 banks', () {
      final mapper = withInnerBanks(buildMapper45(), const [
        10,
        20,
        30,
        31,
        32,
        33,
        0,
        1,
      ]);

      expect(mapper.ppuRead(0x0800), 0);
      expect(mapper.ppuRead(0x0801), 0);
    });
  });

  group('outer register port', () {
    test('four writes fill the four registers in order', () {
      final mapper = buildMapper45();

      writeOuter(mapper, const [0x11, 0x22, 0x0f, 0x04]);

      expect(mapper.outerRegisters, const [0x11, 0x22, 0x0f, 0x04]);
      expect(mapper.writeIndex, 0);
    });

    test('the fifth write wraps back to register 0', () {
      final mapper = buildMapper45();

      writeOuter(mapper, const [0x11, 0x22, 0x0f, 0x04, 0x99]);

      expect(mapper.outerRegisters, const [0x99, 0x22, 0x0f, 0x04]);
      expect(mapper.writeIndex, 1);
    });

    test(r'any even address in $6000-$6FFF reaches the port', () {
      final mapper = buildMapper45()..cpuWrite(0x6ffe, 0x33);

      expect(mapper.outerRegisters[0], 0x33);
      expect(mapper.writeIndex, 1);
    });

    test(r'$7000-$7FFF does not reach the port', () {
      final mapper = buildMapper45()
        ..cpuWrite(0x7000, 0x33)
        ..cpuWrite(0x7ffe, 0x44);

      expect(mapper.outerRegisters, const [0, 0, 0, 0]);
      expect(mapper.writeIndex, 0);
    });

    test('addresses outside the WRAM window are not decoded', () {
      final mapper = buildMapper45()
        ..cpuWrite(0x5000, 0x33)
        ..cpuWrite(0x8000, 0x02);

      expect(mapper.outerRegisters, const [0, 0, 0, 0]);
    });

    test('port writes re-map the PRG windows immediately', () {
      final mapper = buildMapper45();

      writeOuter(mapper, const [0x00, 0x40]);

      expect(mapper.cpuRead(0xe000), 0x7f);
    });
  });

  group('lock and reset', () {
    test('register 3 bit 6 locks the port', () {
      final mapper = buildMapper45();

      writeOuter(mapper, const [0x11, 0x22, 0x0f, 0x44]);

      expect(mapper.locked, isTrue);

      writeOuter(mapper, const [0x99, 0x99]);

      expect(mapper.outerRegisters, const [0x11, 0x22, 0x0f, 0x44]);
      expect(mapper.writeIndex, 0);
    });

    test('register 3 bit 7 alone does not lock the port', () {
      final mapper = buildMapper45();

      writeOuter(mapper, const [0x11, 0x22, 0x0f, 0x80]);

      expect(mapper.locked, isFalse);

      mapper.cpuWrite(0x6000, 0x33);

      expect(mapper.outerRegisters[0], 0x33);
    });

    test(r'an odd $6000-$6FFF write clears the registers and the lock', () {
      final mapper = buildMapper45();

      writeOuter(mapper, const [0x11, 0x22, 0x0f, 0x44]);

      mapper.cpuWrite(0x6001, 0xff);

      expect(mapper.outerRegisters, const [0, 0, 0, 0]);
      expect(mapper.writeIndex, 0);
      expect(mapper.locked, isFalse);

      // The next write goes to register 0 again.
      mapper.cpuWrite(0x6000, 0x07);

      expect(mapper.outerRegisters[0], 0x07);
    });

    test(r'an odd $7000-$7FFF write does not reset the registers', () {
      final mapper = buildMapper45();

      writeOuter(mapper, const [0x11, 0x22]);

      mapper.cpuWrite(0x7001, 0xff);

      expect(mapper.outerRegisters, const [0x11, 0x22, 0, 0]);
      expect(mapper.writeIndex, 2);
    });

    test('console reset clears the registers, index and lock', () {
      final mapper = buildMapper45();

      writeOuter(mapper, const [0x11, 0x22, 0x0f, 0x44]);

      mapper.reset();

      expect(mapper.outerRegisters, const [0, 0, 0, 0]);
      expect(mapper.writeIndex, 0);
      expect(mapper.locked, isFalse);
    });
  });

  group('PRG masking', () {
    test('PRG-AND limits the inner bank bits (inverted encoding)', () {
      final mapper = withInnerBanks(buildMapper45(), const [
        0,
        0,
        0,
        0,
        0,
        0,
        0x23,
        0x05,
      ]);

      writeOuter(mapper, const [0x00, 0x00, 0x0f, 0x20]);

      expect(mapper.prgAnd, 0x1f);
      expect(mapper.cpuRead(0x8000), 0x03); // 0x23 & 0x1f
      expect(mapper.cpuRead(0xa000), 0x05);
    });

    test('PRG-OR offsets the inner block', () {
      final mapper = withInnerBanks(buildMapper45(), const [
        0,
        0,
        0,
        0,
        0,
        0,
        0x03,
        0x05,
      ]);

      writeOuter(mapper, const [0x00, 0x80, 0x0f, 0x20]);

      expect(mapper.cpuRead(0x8000), 0x83);
      expect(mapper.cpuRead(0xa000), 0x85);
    });

    test('the fixed banks stay inside the selected block', () {
      final mapper = buildMapper45();

      writeOuter(mapper, const [0x00, 0x40, 0x0f, 0x20]);

      expect(mapper.cpuRead(0xc000), 0x5e); // (-2 & 0x1f) | 0x40
      expect(mapper.cpuRead(0xe000), 0x5f); // (-1 & 0x1f) | 0x40
    });

    test('PRG bank mode 1 swaps windows within the block', () {
      final mapper = withInnerBanks(buildMapper45(), const [
        0,
        0,
        0,
        0,
        0,
        0,
        0x03,
        0x05,
      ]);

      writeOuter(mapper, const [0x00, 0x40, 0x0f, 0x20]);

      mapper.cpuWrite(0x8000, 0x40 | 6);

      expect(mapper.cpuRead(0x8000), 0x5e);
      expect(mapper.cpuRead(0xc000), 0x43);
    });

    test('register 2 bits 6-7 contribute PRG A21-A22 to the OR', () {
      final mapper = buildMapper45();

      writeOuter(mapper, const [0x00, 0x12, 0xc0, 0x00]);

      expect(mapper.prgOr, 0x312);
    });
  });

  group('CHR masking', () {
    test('CHR-AND is a bit-count encoding', () {
      final mapper = buildMapper45();

      writeOuter(mapper, const [0x00, 0x00, 0x08, 0x00]);

      expect(mapper.chrAnd, 0x01); // $8 -> 1 bit -> 2 KiB

      mapper.cpuWrite(0x6001, 0);
      writeOuter(mapper, const [0x00, 0x00, 0x0e, 0x00]);

      expect(mapper.chrAnd, 0x7f); // $E -> 7 bits -> 128 KiB

      mapper.cpuWrite(0x6001, 0);
      writeOuter(mapper, const [0x00, 0x00, 0x07, 0x00]);

      expect(mapper.chrAnd, 0x00); // $7-$0 -> 0 bits -> 1 KiB
    });

    test('CHR-AND and CHR-OR compose over the MMC3 banks', () {
      final mapper = withInnerBanks(buildMapper45(), const [
        10,
        20,
        30,
        31,
        32,
        33,
        0,
        1,
      ]);

      writeOuter(mapper, const [0x40, 0x00, 0x08, 0x00]);

      expect(mapper.ppuRead(0x0000), 0x40); // (10 & 1) | 0x40
      expect(mapper.ppuRead(0x0400), 0x41); // (11 & 1) | 0x40
      expect(mapper.ppuRead(0x1400), 0x41); // (31 & 1) | 0x40
    });

    test('register 2 bit 4 contributes CHR A18 to the OR', () {
      final mapper = withInnerBanks(buildMapper45(), const [
        10,
        20,
        30,
        31,
        32,
        33,
        0,
        1,
      ]);

      writeOuter(mapper, const [0x00, 0x00, 0x1f, 0x00]);

      expect(mapper.chrOr, 0x100);
      expect(mapper.ppuRead(0x0000), 0x0a); // page 0x10a low tag
      expect(mapper.ppuRead(0x0001), 0x01); // page 0x10a high tag
    });

    test('register 2 bits 6-7 contribute CHR A20-A21 to the OR', () {
      final mapper = buildMapper45();

      writeOuter(mapper, const [0x05, 0x00, 0xdf, 0x00]);

      expect(mapper.chrOr, 0xd05);
    });

    test('CHR-RAM carts bypass the CHR masking', () {
      final mapper =
          withInnerBanks(buildMapper45(chrRam: true), const [
              0,
              2,
              4,
              5,
              6,
              7,
              0,
              1,
            ])
            ..ppuWrite(0x0000, 0x11)
            ..ppuWrite(0x0800, 0x22);

      expect(mapper.ppuRead(0x0000), 0x11);
      expect(mapper.ppuRead(0x0800), 0x22);
    });
  });

  group('WRAM', () {
    test('port writes also land in WRAM', () {
      final mapper = buildMapper45()..cpuWrite(0x6000, 0x35);

      expect(mapper.cpuRead(0x6000), 0x35);
      expect(mapper.outerRegisters[0], 0x35);
    });

    test('locked writes still land in WRAM', () {
      final mapper = buildMapper45();

      writeOuter(mapper, const [0x11, 0x22, 0x0f, 0x44]);

      mapper.cpuWrite(0x6000, 0x77);

      expect(mapper.cpuRead(0x6000), 0x77);
      expect(mapper.outerRegisters[0], 0x11);
    });

    test(r'$7000-$7FFF is plain WRAM', () {
      final mapper = buildMapper45()..cpuWrite(0x7123, 0x99);

      expect(mapper.cpuRead(0x7123), 0x99);
      expect(mapper.outerRegisters, const [0, 0, 0, 0]);
    });
  });

  group('inherited MMC3 behavior', () {
    test(r'$A000 mirroring control still works', () {
      final mapper = buildMapper45()
        ..cpuWrite(0xa000, 0)
        ..ppuWrite(0x2000, 0x11);

      expect(mapper.ppuRead(0x2800), 0x11);

      mapper
        ..cpuWrite(0xa000, 1)
        ..ppuWrite(0x2000, 0x22);

      expect(mapper.ppuRead(0x2400), 0x22);
    });

    test('open masks give plain MMC3 banking', () {
      final mapper = withInnerBanks(buildMapper45(), const [
        10,
        20,
        30,
        31,
        32,
        33,
        3,
        5,
      ]);

      writeOuter(mapper, const [0x00, 0x00, 0x0f, 0x00]);

      expect(mapper.cpuRead(0x8000), 3);
      expect(mapper.cpuRead(0xa000), 5);
      expect(mapper.cpuRead(0xe000), 0x3f);
      expect(mapper.ppuRead(0x0000), 10);
      expect(mapper.ppuRead(0x0800), 20);
      expect(mapper.ppuRead(0x1c00), 33);
    });
  });
}
