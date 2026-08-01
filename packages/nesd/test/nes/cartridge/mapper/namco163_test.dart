import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cpu/irq_source.dart';

import 'namco163_harness.dart';

void main() {
  group('PRG banking', () {
    test(r'$E000, $E800 and $F000 select the three switchable banks', () {
      final mapper = buildNamco163()
        ..cpuWrite(0xe000, 3)
        ..cpuWrite(0xe800, 5)
        ..cpuWrite(0xf000, 7);

      expect(mapper.cpuRead(0x8000), 0xb0 + 3);
      expect(mapper.cpuRead(0xa000), 0xb0 + 5);
      expect(mapper.cpuRead(0xc000), 0xb0 + 7);
    });

    test(r'$E000 masks the bank to 6 bits', () {
      final mapper = buildNamco163()..cpuWrite(0xe000, 0xc3);

      expect(mapper.cpuRead(0x8000), 0xb0 + 3);
    });

    test(r'$E000-$FFFF is fixed to the last bank', () {
      final mapper = buildNamco163()
        ..reset()
        ..cpuWrite(0xe000, 3);

      expect(mapper.cpuRead(0xe000), 0xb0 + 15);
    });
  });

  group('CHR banking', () {
    test('the twelve registers map twelve 1KB pages', () {
      final mapper = buildNamco163();

      for (var bank = 0; bank < 12; bank++) {
        mapper.cpuWrite(0x8000 + bank * 0x800, bank + 1);
      }

      for (var bank = 0; bank < 8; bank++) {
        expect(mapper.ppuRead(bank * 0x400), 0x10 + bank + 1);
      }
    });
  });

  group('nametable disable', () {
    test(r'$E800 bits 6 and 7 route the CHR pages to nametables', () {
      final mapper = buildNamco163()..cpuWrite(0xe800, 0xc0);

      expect(mapper.state.disableNametables0, true);
      expect(mapper.state.disableNametables1, true);
    });

    test('both default to enabled after reset', () {
      final mapper = buildNamco163();

      expect(mapper.state.disableNametables0, false);
      expect(mapper.state.disableNametables1, false);
    });
  });

  group('PRG RAM write protect', () {
    test(r'$F800 with the $40 nybble and a clear bit enables writes', () {
      final mapper = buildNamco163()
        ..cpuWrite(0xf800, 0x40)
        ..cpuWrite(0x6000, 0x42);

      expect(mapper.cpuRead(0x6000), 0x42);
    });

    test('a wrong upper nybble leaves PRG RAM read-only', () {
      final mapper = buildNamco163()
        ..cpuWrite(0xf800, 0x40)
        ..cpuWrite(0x6000, 0x42)
        ..cpuWrite(0xf800, 0x00)
        ..cpuWrite(0x6000, 0x99);

      expect(mapper.cpuRead(0x6000), 0x42);
    });
  });

  group('scanline IRQ', () {
    test(r'$5000 and $5800 assemble the 15-bit counter', () {
      final mapper = buildNamco163()
        ..cpuWrite(0x5000, 0x34)
        ..cpuWrite(0x5800, 0x12);

      expect(mapper.cpuRead(0x5000), 0x34);
      expect(mapper.cpuRead(0x5800) & 0x7f, 0x12);
    });

    test(r'$5800 bit 7 enables the IRQ and reads back', () {
      final mapper = buildNamco163()..cpuWrite(0x5800, 0x80);

      expect(mapper.cpuRead(0x5800) & 0x80, 0x80);
    });

    test('the counter fires at 0x7fff when enabled', () {
      final mapper = buildNamco163()
        ..cpuWrite(0x5000, 0xfd)
        ..cpuWrite(0x5800, 0xff)
        ..step()
        ..step();

      expect(mapper.bus.cpu.irq & IrqSource.mapper.value, isNot(0));
    });
  });

  group(r'$4800 is the sound port, not the IRQ counter', () {
    test('writing it leaves the IRQ counter alone', () {
      final mapper = buildNamco163()
        ..cpuWrite(0x5000, 0x34)
        ..cpuWrite(0x4800, 0xff);

      expect(mapper.cpuRead(0x5000), 0x34);
    });

    test('reading it does not return the IRQ counter', () {
      final mapper = buildNamco163()..cpuWrite(0x5000, 0x34);

      expect(mapper.cpuRead(0x4800), isNot(0x34));
    });
  });
}
