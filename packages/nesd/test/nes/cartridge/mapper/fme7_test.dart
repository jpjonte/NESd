import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/tables.dart';
import 'package:nesd/nes/cpu/irq_source.dart';

import 'fme7_harness.dart';

void main() {
  group('PRG banking', () {
    test('commands 9, A and B select the three switchable 8 KB banks', () {
      final mapper = buildFme7();

      write(mapper, 0x9, 3);
      write(mapper, 0xa, 5);
      write(mapper, 0xb, 7);

      expect(mapper.cpuRead(0x8000), 0xb0 + 3);
      expect(mapper.cpuRead(0xa000), 0xb0 + 5);
      expect(mapper.cpuRead(0xc000), 0xb0 + 7);
    });

    test(r'$E000-$FFFF is fixed to the last bank', () {
      final mapper = buildFme7();

      write(mapper, 0xb, 7);

      expect(mapper.cpuRead(0xe000), 0xb0 + 15);
    });

    test('a bank number is masked to 6 bits', () {
      final mapper = buildFme7();

      write(mapper, 0x9, 0xc3);

      expect(mapper.cpuRead(0x8000), 0xb0 + 3);
    });

    test('the command latch survives writes to other addresses', () {
      final mapper = buildFme7()
        ..cpuWrite(0x9ffe, 0x9)
        ..cpuWrite(0xbfff, 4);

      expect(mapper.cpuRead(0x8000), 0xb0 + 4);
    });
  });

  group('CHR banking', () {
    test('commands 0 to 7 map eight 1 KB pages', () {
      final mapper = buildFme7();

      for (var command = 0; command < 8; command++) {
        write(mapper, command, command + 1);
      }

      for (var slot = 0; slot < 8; slot++) {
        expect(mapper.ppuRead(slot * 0x400), 0x10 + slot + 1);
      }
    });

    test('a CHR bank uses all eight parameter bits', () {
      final mapper = buildFme7();

      write(mapper, 0x0, 0xff);

      expect(mapper.ppuRead(0x0000), 0x10 + 0xff % 64);
    });
  });

  group(r'the $6000 window', () {
    test('command 8 maps a PRG ROM bank while bit 6 is clear', () {
      final mapper = buildFme7();

      write(mapper, 0x8, 5);

      expect(mapper.cpuRead(0x6000), 0xb0 + 5);
    });

    test('bits 6 and 7 map writable PRG RAM', () {
      final mapper = buildFme7();

      write(mapper, 0x8, 0xc0);

      mapper.cpuWrite(0x6000, 0x42);

      expect(mapper.cpuRead(0x6000), 0x42);
    });

    test('RAM selected but disabled reads as open bus', () {
      final mapper = buildFme7();

      write(mapper, 0x8, 0xc0);

      mapper.cpuWrite(0x6000, 0x42);

      write(mapper, 0x8, 0x40);

      expect(mapper.cpuRead(0x6000), 0);
    });

    test('disabled RAM ignores writes', () {
      final mapper = buildFme7();

      write(mapper, 0x8, 0x40);

      mapper.cpuWrite(0x6000, 0x99);

      write(mapper, 0x8, 0xc0);

      expect(mapper.cpuRead(0x6000), 0);
    });

    test('a battery cartridge banks its save RAM', () {
      final mapper = buildFme7(battery: true);

      write(mapper, 0x8, 0xc0);

      mapper.cpuWrite(0x6000, 0x42);

      expect(mapper.cartridge.prgSaveRam[0], 0x42);
    });
  });

  group('nametable arrangement', () {
    test('command C value 0 arranges the nametables horizontally', () {
      final mapper = buildFme7();

      write(mapper, 0xc, 0);

      mapper
        ..ppuWrite(0x2000, 0x11)
        ..ppuWrite(0x2400, 0x22);

      expect(mapper.ppuRead(0x2800), 0x11);
      expect(mapper.ppuRead(0x2c00), 0x22);
    });

    test('command C value 1 arranges the nametables vertically', () {
      final mapper = buildFme7();

      write(mapper, 0xc, 1);

      mapper
        ..ppuWrite(0x2000, 0x11)
        ..ppuWrite(0x2800, 0x22);

      expect(mapper.ppuRead(0x2400), 0x11);
      expect(mapper.ppuRead(0x2c00), 0x22);
    });

    test('command C value 2 selects the first single screen', () {
      final mapper = buildFme7();

      write(mapper, 0xc, 2);

      mapper.ppuWrite(0x2c00, 0x11);

      expect(mapper.ppuRead(0x2000), 0x11);
      expect(mapper.bus.ppu.ram[0], 0x11);
    });

    test('command C value 3 selects the second single screen', () {
      final mapper = buildFme7();

      write(mapper, 0xc, 3);

      mapper.ppuWrite(0x2000, 0x11);

      expect(mapper.ppuRead(0x2c00), 0x11);
      expect(mapper.bus.ppu.ram[0x400], 0x11);
    });

    test('only the low two bits select the arrangement', () {
      final mapper = buildFme7();

      write(mapper, 0xc, 0xfd);

      mapper
        ..ppuWrite(0x2000, 0x11)
        ..ppuWrite(0x2800, 0x22);

      expect(mapper.ppuRead(0x2400), 0x11);
    });
  });

  group('IRQ', () {
    test('commands E and F assemble the 16-bit counter', () {
      final mapper = buildFme7();

      write(mapper, 0xe, 0x34);
      write(mapper, 0xf, 0x12);

      expect(mapper.state.irqCounter, 0x1234);
    });

    test('the counter fires when it wraps past zero', () {
      final mapper = buildFme7();

      write(mapper, 0xe, 2);
      write(mapper, 0xf, 0);
      write(mapper, 0xd, 0x81);

      mapper
        ..step()
        ..step();

      expect(mapper.bus.cpu.irq & IrqSource.mapper.value, 0);

      mapper.step();

      expect(mapper.bus.cpu.irq & IrqSource.mapper.value, isNot(0));
      expect(mapper.state.irqCounter, 0xffff);
    });

    test('the counter keeps running after it fired', () {
      final mapper = buildFme7();

      write(mapper, 0xe, 0);
      write(mapper, 0xf, 0);
      write(mapper, 0xd, 0x81);

      mapper
        ..step()
        ..step();

      expect(mapper.state.irqCounter, 0xfffe);
    });

    test('a cleared counter enable bit freezes the counter', () {
      final mapper = buildFme7();

      write(mapper, 0xe, 0x10);
      write(mapper, 0xf, 0);
      write(mapper, 0xd, 0x01);

      mapper
        ..step()
        ..step();

      expect(mapper.state.irqCounter, 0x0010);
      expect(mapper.bus.cpu.irq & IrqSource.mapper.value, 0);
    });

    test('the wrap is silent while the IRQ enable bit is clear', () {
      final mapper = buildFme7();

      write(mapper, 0xe, 0);
      write(mapper, 0xf, 0);
      write(mapper, 0xd, 0x80);

      mapper.step();

      expect(mapper.bus.cpu.irq & IrqSource.mapper.value, 0);
    });

    test('any write to command D acknowledges a pending IRQ', () {
      final mapper = buildFme7();

      write(mapper, 0xe, 0);
      write(mapper, 0xf, 0);
      write(mapper, 0xd, 0x81);

      mapper.step();

      expect(mapper.bus.cpu.irq & IrqSource.mapper.value, isNot(0));

      write(mapper, 0xd, 0x81);

      expect(mapper.bus.cpu.irq & IrqSource.mapper.value, 0);
    });

    test('the counter runs every CPU cycle', () {
      final mapper = buildFme7();

      expect(mapper.needsStep, true);
    });
  });

  group('5B audio', () {
    test('the mapper exposes its chip as expansion audio', () {
      final mapper = buildFme7();

      expect(mapper.expansionAudio, same(mapper.audio));
    });

    test(r'$C000 selects an audio register and $E000 writes it', () {
      final mapper = buildFme7()
        ..cpuWrite(0xc000, 0x08)
        ..cpuWrite(0xe000, 0x0f);

      expect(mapper.audio.registers[0x08], 0x0f);
    });

    test('the audio ports leave the bank registers alone', () {
      final mapper = buildFme7();

      write(mapper, 0x9, 3);

      mapper
        ..cpuWrite(0xc000, 0x9)
        ..cpuWrite(0xe000, 0x7);

      expect(mapper.cpuRead(0x8000), 0xb0 + 3);
    });

    test('the chip runs off the mapper step', () {
      final mapper = buildFme7()
        ..cpuWrite(0xc000, 0x00)
        ..cpuWrite(0xe000, 0x01)
        ..cpuWrite(0xc000, 0x07)
        ..cpuWrite(0xe000, 0x3e)
        ..cpuWrite(0xc000, 0x08)
        ..cpuWrite(0xe000, 0x0f);

      for (var i = 0; i < sunsoft5bPrescaler; i++) {
        mapper.step();
      }

      expect(mapper.audio.output, greaterThan(0));
    });
  });
}
