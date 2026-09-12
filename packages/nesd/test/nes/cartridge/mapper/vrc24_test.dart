import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/vrc24.dart';

import 'vrc24_harness.dart';

void main() {
  group('board variants', () {
    test('mapper 22 is a VRC2', () {
      expect(buildVrc24(mapper: 22, subMapper: 0).name, 'Konami VRC2');
    });

    test('submapper 3 on mapper 23 is a VRC2', () {
      expect(buildVrc24(subMapper: 3).name, 'Konami VRC2');
    });

    test('submapper 1 on mapper 23 is a VRC4', () {
      expect(buildVrc24().name, 'Konami VRC4');
    });

    test('an unknown submapper is treated as a VRC4', () {
      expect(buildVrc24(mapper: 25, subMapper: 0).name, 'Konami VRC4');
    });
  });

  group('register address lines', () {
    const boards = <(int, int, int, int)>[
      (21, 1, 0xb002, 0xb004), // VRC4a: A1, A2
      (21, 2, 0xb040, 0xb080), // VRC4c: A6, A7
      (22, 0, 0xb002, 0xb001), // VRC2a: A1, A0
      (23, 1, 0xb001, 0xb002), // VRC4f: A0, A1
      (23, 2, 0xb004, 0xb008), // VRC4e: A2, A3
      (23, 3, 0xb001, 0xb002), // VRC2b: A0, A1
      (25, 1, 0xb002, 0xb001), // VRC4b: A1, A0
      (25, 2, 0xb008, 0xb004), // VRC4d: A3, A2
      (25, 3, 0xb002, 0xb001), // VRC2c: A1, A0
    ];

    for (final (mapperId, subMapper, register1, register2) in boards) {
      test('mapper $mapperId submapper $subMapper', () {
        final mapper = buildVrc24(mapper: mapperId, subMapper: subMapper)
          ..cpuWrite(0xb000, 0x4)
          ..cpuWrite(register1, 0x1)
          ..cpuWrite(register2, 0x6);

        final shift = mapperId == 22 ? 1 : 0;

        expect(chrPageAt(mapper, 0x0000), 0x14 >> shift);
        expect(chrPageAt(mapper, 0x0400), 0x6 >> shift);
      });
    }

    const heuristics = <(int, int, int)>[
      (21, 0xb002, 0xb040),
      (23, 0xb001, 0xb004),
      (25, 0xb002, 0xb008),
    ];

    for (final (mapperId, first, second) in heuristics) {
      test('mapper $mapperId without a submapper decodes both boards', () {
        final mapper = buildVrc24(mapper: mapperId, subMapper: 0)
          ..cpuWrite(0xb000, 0x4)
          ..cpuWrite(first, 0x1);

        expect(chrPageAt(mapper, 0x0000), 0x14);

        mapper.cpuWrite(second, 0x2);

        expect(chrPageAt(mapper, 0x0000), 0x24);
      });
    }
  });

  group('PRG banking', () {
    test(r'$8000 selects the 8 KiB bank at $8000', () {
      final mapper = buildVrc24()..cpuWrite(0x8000, 3);

      expect(mapper.cpuRead(0x8000), 0xb0 + 3);
    });

    test(r'$A000 selects the 8 KiB bank at $A000', () {
      final mapper = buildVrc24()..cpuWrite(0xa000, 5);

      expect(mapper.cpuRead(0xa000), 0xb0 + 5);
    });

    test('the upper two banks are fixed to the end of the ROM', () {
      final mapper = buildVrc24();

      expect(mapper.cpuRead(0xc000), 0xb0 + prgBankCount - 2);
      expect(mapper.cpuRead(0xe000), 0xb0 + prgBankCount - 1);
    });

    test('a bank number is masked to 5 bits', () {
      final mapper = buildVrc24()..cpuWrite(0x8000, 0xe3);

      expect(mapper.cpuRead(0x8000), 0xb0 + 3);
    });

    test('every register index of the range selects the bank', () {
      final mapper = buildVrc24()..cpuWrite(0x8003, 4);

      expect(mapper.cpuRead(0x8000), 0xb0 + 4);
    });

    test(r'swap mode exchanges the $8000 and $C000 banks', () {
      final mapper = buildVrc24()..cpuWrite(0x8000, 3);

      writeRegister(mapper, 0x9000, 2, 0x02);

      expect(mapper.cpuRead(0x8000), 0xb0 + prgBankCount - 2);
      expect(mapper.cpuRead(0xc000), 0xb0 + 3);
    });

    test('swap mode reads the register as written later', () {
      final mapper = buildVrc24();

      writeRegister(mapper, 0x9000, 2, 0x02);

      mapper.cpuWrite(0x8000, 7);

      expect(mapper.cpuRead(0xc000), 0xb0 + 7);
    });

    test('a VRC2 has no swap mode', () {
      final mapper = buildVrc24(subMapper: 3)..cpuWrite(0x8000, 3);

      writeRegister(mapper, 0x9000, 2, 0x02);

      expect(mapper.cpuRead(0x8000), 0xb0 + 3);
    });
  });

  group('CHR banking', () {
    test('each of the eight slots maps its own 1 KiB page', () {
      final mapper = buildVrc24();

      for (var slot = 0; slot < 8; slot++) {
        selectChr(mapper, slot, slot + 1);
      }

      for (var slot = 0; slot < 8; slot++) {
        expect(chrPageAt(mapper, slot * 0x400), slot + 1);
      }
    });

    test('a VRC4 page number has nine bits', () {
      final mapper = buildVrc24();

      selectChr(mapper, 0, 0x1ff);

      expect(chrPageAt(mapper, 0x0000), 0x1ff);
    });

    test('a low-nibble write keeps the high bits', () {
      final mapper = buildVrc24();

      selectChr(mapper, 0, 0x1f5);

      writeRegister(mapper, 0xb000, 0, 0x3);

      expect(chrPageAt(mapper, 0x0000), 0x1f3);
    });

    test('a high-bits write keeps the low nibble', () {
      final mapper = buildVrc24();

      selectChr(mapper, 0, 0x1f5);

      writeRegister(mapper, 0xb000, 1, 0x02);

      expect(chrPageAt(mapper, 0x0000), 0x025);
    });

    test('a VRC2 page number has eight bits', () {
      final mapper = buildVrc24(subMapper: 3);

      selectChr(mapper, 0, 0x1ff);

      expect(chrPageAt(mapper, 0x0000), 0xff);
    });

    test('a VRC2a drops the low bit of the page number', () {
      final mapper = buildVrc24(mapper: 22, subMapper: 0, chrPages: 128);

      selectChr(mapper, 1, 0x0b);

      expect(chrPageAt(mapper, 0x0400), 5);

      selectChr(mapper, 1, 0x0a);

      expect(chrPageAt(mapper, 0x0400), 5);
    });
  });

  group('mirroring', () {
    test('a VRC4 defaults to the header layout', () {
      final mapper = buildVrc24()
        ..ppuWrite(0x2000, 0x11)
        ..ppuWrite(0x2800, 0x22);

      expect(mapper.ppuRead(0x2400), 0x11);
      expect(mapper.ppuRead(0x2c00), 0x22);
    });

    test('value 0 mirrors vertically', () {
      final mapper = buildVrc24()
        ..cpuWrite(0x9000, 0)
        ..ppuWrite(0x2000, 0x11)
        ..ppuWrite(0x2400, 0x22);

      expect(mapper.ppuRead(0x2800), 0x11);
      expect(mapper.ppuRead(0x2c00), 0x22);
    });

    test('value 1 mirrors horizontally', () {
      final mapper = buildVrc24()
        ..cpuWrite(0x9000, 0)
        ..cpuWrite(0x9000, 1)
        ..ppuWrite(0x2000, 0x11)
        ..ppuWrite(0x2800, 0x22);

      expect(mapper.ppuRead(0x2400), 0x11);
      expect(mapper.ppuRead(0x2c00), 0x22);
    });

    test('value 2 selects the lower single screen', () {
      final mapper = buildVrc24()
        ..cpuWrite(0x9000, 2)
        ..ppuWrite(0x2c00, 0x11);

      expect(mapper.ppuRead(0x2000), 0x11);
      expect(mapper.bus.ppu.ram[0], 0x11);
    });

    test('value 3 selects the upper single screen', () {
      final mapper = buildVrc24()
        ..cpuWrite(0x9000, 3)
        ..ppuWrite(0x2000, 0x11);

      expect(mapper.ppuRead(0x2c00), 0x11);
      expect(mapper.bus.ppu.ram[0x400], 0x11);
    });

    test('a VRC4 ignores mirroring writes to registers 2 and 3', () {
      final mapper = buildVrc24()..cpuWrite(0x9000, 0);

      writeRegister(mapper, 0x9000, 2, 1);

      mapper
        ..ppuWrite(0x2000, 0x11)
        ..ppuWrite(0x2400, 0x22);

      expect(mapper.ppuRead(0x2800), 0x11);
      expect(mapper.ppuRead(0x2c00), 0x22);
    });

    test('a VRC2 only mirrors vertically or horizontally', () {
      final mapper = buildVrc24(subMapper: 3)
        ..cpuWrite(0x9000, 3)
        ..ppuWrite(0x2000, 0x11)
        ..ppuWrite(0x2800, 0x22);

      expect(mapper.ppuRead(0x2400), 0x11);
      expect(mapper.ppuRead(0x2c00), 0x22);

      mapper
        ..cpuWrite(0x9000, 2)
        ..ppuWrite(0x2000, 0x33)
        ..ppuWrite(0x2400, 0x44);

      expect(mapper.ppuRead(0x2800), 0x33);
      expect(mapper.ppuRead(0x2c00), 0x44);
    });

    test('a VRC2 takes mirroring from every register of the range', () {
      final mapper = buildVrc24(subMapper: 3)
        ..cpuWrite(0x9002, 0)
        ..ppuWrite(0x2000, 0x11)
        ..ppuWrite(0x2400, 0x22);

      expect(mapper.ppuRead(0x2800), 0x11);
      expect(mapper.ppuRead(0x2c00), 0x22);
    });
  });

  group(r'the $6000 window', () {
    test('without PRG RAM a write latches its low bit', () {
      final mapper = buildVrc24()..cpuWrite(0x6000, 0xff);

      expect(mapper.cpuRead(0x6000) & 1, 1);

      mapper.cpuWrite(0x6000, 0xfe);

      expect(mapper.cpuRead(0x6000) & 1, 0);
    });

    test('the other seven bits of the latch read as open bus', () {
      final mapper = buildVrc24()..cpuWrite(0x6000, 1);

      mapper.bus.cpu.openBus = 0x5e;

      expect(mapper.cpuRead(0x6000), 0x5f);
    });

    test('PRG RAM fills the window', () {
      final mapper = buildVrc24(prgRamSize: 0x2000)
        ..cpuWrite(0x6000, 0x42)
        ..cpuWrite(0x7fff, 0x43);

      expect(mapper.cpuRead(0x6000), 0x42);
      expect(mapper.cpuRead(0x7fff), 0x43);
    });

    test('2 KiB of PRG RAM repeats through the window', () {
      final mapper = buildVrc24(prgRamSize: 0x800)..cpuWrite(0x6000, 0x42);

      expect(mapper.cpuRead(0x6800), 0x42);
      expect(mapper.cpuRead(0x7800), 0x42);
    });

    test('a battery cartridge keeps the window in its save RAM', () {
      final mapper = buildVrc24(battery: true)..cpuWrite(0x6000, 0x42);

      expect(mapper.cartridge.prgSaveRam[0], 0x42);
    });

    test('a VRC4 disables the RAM with bit 0 of register 2', () {
      final mapper = buildVrc24(prgRamSize: 0x2000)..cpuWrite(0x6000, 0x42);

      writeRegister(mapper, 0x9000, 2, 0x00);

      expect(mapper.cpuRead(0x6000), 0);

      mapper.cpuWrite(0x6000, 0x99);

      writeRegister(mapper, 0x9000, 2, 0x01);

      expect(mapper.cpuRead(0x6000), 0x42);
    });

    test('a VRC2 keeps its RAM enabled', () {
      final mapper = buildVrc24(subMapper: 3, prgRamSize: 0x2000)
        ..cpuWrite(0x6000, 0x42);

      writeRegister(mapper, 0x9000, 2, 0x00);

      expect(mapper.cpuRead(0x6000), 0x42);
    });
  });

  group('IRQ', () {
    void step(VRC24 mapper, int cycles) {
      for (var i = 0; i < cycles; i++) {
        mapper.step();
      }
    }

    test('registers 0 and 1 assemble the latch', () {
      final mapper = buildVrc24();

      writeRegister(mapper, 0xf000, 0, 0x4);
      writeRegister(mapper, 0xf000, 1, 0xa);

      expect(mapper.state.irqLatch, 0xa4);
    });

    test('the latch registers only take the low nibble', () {
      final mapper = buildVrc24();

      writeRegister(mapper, 0xf000, 0, 0xf4);
      writeRegister(mapper, 0xf000, 1, 0xfa);

      expect(mapper.state.irqLatch, 0xa4);
    });

    test('enabling the counter reloads it from the latch', () {
      final mapper = buildVrc24();

      writeRegister(mapper, 0xf000, 0, 0x0);
      writeRegister(mapper, 0xf000, 1, 0x3);
      writeRegister(mapper, 0xf000, 2, 0x02);

      expect(mapper.state.irqCounter, 0x30);
    });

    test('scanline mode clocks the counter every 114, 114, 113 cycles', () {
      final mapper = buildVrc24();

      writeRegister(mapper, 0xf000, 2, 0x02);

      step(mapper, 113);

      expect(mapper.state.irqCounter, 0);

      step(mapper, 1);

      expect(mapper.state.irqCounter, 1);

      step(mapper, 114);

      expect(mapper.state.irqCounter, 2);

      step(mapper, 112);

      expect(mapper.state.irqCounter, 2);

      step(mapper, 1);

      expect(mapper.state.irqCounter, 3);
    });

    test(r'the counter fires and reloads when it wraps past $FF', () {
      final mapper = buildVrc24();

      writeRegister(mapper, 0xf000, 0, 0xe);
      writeRegister(mapper, 0xf000, 1, 0xf);
      writeRegister(mapper, 0xf000, 2, 0x02);

      step(mapper, 114);

      expect(irqPending(mapper), false);
      expect(mapper.state.irqCounter, 0xff);

      step(mapper, 114);

      expect(irqPending(mapper), true);
      expect(mapper.state.irqCounter, 0xfe);
    });

    test('cycle mode clocks the counter every CPU cycle', () {
      final mapper = buildVrc24();

      writeRegister(mapper, 0xf000, 0, 0xe);
      writeRegister(mapper, 0xf000, 1, 0xf);
      writeRegister(mapper, 0xf000, 2, 0x06);

      step(mapper, 1);

      expect(irqPending(mapper), false);

      step(mapper, 1);

      expect(irqPending(mapper), true);
    });

    test('a disabled counter does not clock', () {
      final mapper = buildVrc24();

      writeRegister(mapper, 0xf000, 0, 0xf);
      writeRegister(mapper, 0xf000, 1, 0xf);
      writeRegister(mapper, 0xf000, 2, 0x04);

      step(mapper, 500);

      expect(irqPending(mapper), false);
      expect(mapper.state.irqCounter, 0);
    });

    test('a control write acknowledges a pending IRQ', () {
      final mapper = buildVrc24();

      writeRegister(mapper, 0xf000, 0, 0xf);
      writeRegister(mapper, 0xf000, 1, 0xf);
      writeRegister(mapper, 0xf000, 2, 0x06);

      step(mapper, 1);

      expect(irqPending(mapper), true);

      writeRegister(mapper, 0xf000, 2, 0x00);

      expect(irqPending(mapper), false);
    });

    test('a control write resets the prescaler', () {
      final mapper = buildVrc24();

      writeRegister(mapper, 0xf000, 2, 0x02);

      step(mapper, 100);

      writeRegister(mapper, 0xf000, 2, 0x02);

      step(mapper, 113);

      expect(mapper.state.irqCounter, 0);

      step(mapper, 1);

      expect(mapper.state.irqCounter, 1);
    });

    test(
      'the acknowledge register keeps the counter running when A is set',
      () {
        final mapper = buildVrc24();

        writeRegister(mapper, 0xf000, 0, 0xf);
        writeRegister(mapper, 0xf000, 1, 0xf);
        writeRegister(mapper, 0xf000, 2, 0x07);

        step(mapper, 1);

        writeRegister(mapper, 0xf000, 3, 0x00);

        expect(irqPending(mapper), false);

        step(mapper, 1);

        expect(irqPending(mapper), true);
      },
    );

    test('the acknowledge register stops the counter when A is clear', () {
      final mapper = buildVrc24();

      writeRegister(mapper, 0xf000, 0, 0xf);
      writeRegister(mapper, 0xf000, 1, 0xf);
      writeRegister(mapper, 0xf000, 2, 0x06);

      step(mapper, 1);

      writeRegister(mapper, 0xf000, 3, 0x00);

      step(mapper, 500);

      expect(irqPending(mapper), false);
    });

    test('a VRC4 steps every CPU cycle', () {
      expect(buildVrc24().needsStep, true);
    });

    test('a VRC2 has no IRQ counter', () {
      final mapper = buildVrc24(subMapper: 3);

      expect(mapper.needsStep, false);

      writeRegister(mapper, 0xf000, 0, 0xf);
      writeRegister(mapper, 0xf000, 1, 0xf);
      writeRegister(mapper, 0xf000, 2, 0x06);

      step(mapper, 500);

      expect(irqPending(mapper), false);
    });
  });
}
