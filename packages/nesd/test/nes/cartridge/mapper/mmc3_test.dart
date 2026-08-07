import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/mmc3.dart';

import 'mmc3_harness.dart';

MMC3 withBanks(List<int> values) {
  final mapper = buildMmc3();

  for (var register = 0; register < 8; register++) {
    mapper
      ..cpuWrite(0x8000, register)
      ..cpuWrite(0x8001, values[register]);
  }

  return mapper;
}

void main() {
  group('PRG banking', () {
    test(r'mode 0 maps R6 at $8000, R7 at $A000, last two fixed', () {
      final mapper = withBanks(const [0, 0, 0, 0, 0, 0, 3, 5]);

      expect(mapper.cpuRead(0x8000), 3);
      expect(mapper.cpuRead(0xa000), 5);
      expect(mapper.cpuRead(0xc000), mmc3PrgBanks - 2);
      expect(mapper.cpuRead(0xe000), mmc3PrgBanks - 1);
    });

    test(r'mode 1 fixes $8000 and moves R6 to $C000', () {
      final mapper = withBanks(const [0, 0, 0, 0, 0, 0, 3, 5])
        ..cpuWrite(0x8000, 0x40 | 6);

      expect(mapper.cpuRead(0x8000), mmc3PrgBanks - 2);
      expect(mapper.cpuRead(0xa000), 5);
      expect(mapper.cpuRead(0xc000), 3);
      expect(mapper.cpuRead(0xe000), mmc3PrgBanks - 1);
    });

    test('R6 and R7 are masked to six bits', () {
      final mapper = withBanks(const [0, 0, 0, 0, 0, 0, 0xc3, 0x85]);

      expect(mapper.state.r6, 3);
      expect(mapper.state.r7, 5);
    });
  });

  group('CHR banking', () {
    test('mode 0 maps two 2 KiB then four 1 KiB banks', () {
      final mapper = withBanks(const [10, 20, 30, 31, 32, 33, 0, 0])
        ..cpuWrite(0x8000, 0);

      expect(mapper.ppuRead(0x0000), 10);
      expect(mapper.ppuRead(0x0400), 11);
      expect(mapper.ppuRead(0x0800), 20);
      expect(mapper.ppuRead(0x0c00), 21);
      expect(mapper.ppuRead(0x1000), 30);
      expect(mapper.ppuRead(0x1400), 31);
      expect(mapper.ppuRead(0x1800), 32);
      expect(mapper.ppuRead(0x1c00), 33);
    });

    test('mode 1 swaps the 4 KiB halves', () {
      final mapper = withBanks(const [10, 20, 30, 31, 32, 33, 0, 0])
        ..cpuWrite(0x8000, 0x80);

      expect(mapper.ppuRead(0x0000), 30);
      expect(mapper.ppuRead(0x0400), 31);
      expect(mapper.ppuRead(0x0800), 32);
      expect(mapper.ppuRead(0x0c00), 33);
      expect(mapper.ppuRead(0x1000), 10);
      expect(mapper.ppuRead(0x1400), 11);
      expect(mapper.ppuRead(0x1800), 20);
      expect(mapper.ppuRead(0x1c00), 21);
    });

    test('R0 and R1 are aligned to 2 KiB', () {
      final mapper = withBanks(const [11, 21, 0, 0, 0, 0, 0, 0])
        ..cpuWrite(0x8000, 0);

      expect(mapper.ppuRead(0x0000), 10);
      expect(mapper.ppuRead(0x0800), 20);
    });
  });

  group('mirroring', () {
    test(r'$A000 bit 0 selects the nametable arrangement', () {
      final mapper = buildMmc3()
        ..cpuWrite(0xa000, 0)
        ..ppuWrite(0x2000, 0x11);

      expect(mapper.ppuRead(0x2800), 0x11);

      mapper
        ..cpuWrite(0xa000, 1)
        ..ppuWrite(0x2000, 0x22);

      expect(mapper.ppuRead(0x2400), 0x22);
    });
  });
}
