import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/vt/vt02.dart';
import 'package:nesd/nes/cpu/irq_source.dart';

import 'vt02_harness.dart';

int _prgBankAt(VT02 mapper, int address) =>
    mapper.cpuRead(address) | (mapper.cpuRead(address + 1) << 8);

int _chrBankAt(VT02 mapper, int address) =>
    mapper.ppuRead(address) | (mapper.ppuRead(address + 1) << 8);

void main() {
  group(r'$8000', () {
    test(r'sets the $4105 index and inversion bits', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x8000, 0xc6);

      expect(mapper.registerAt(0x4105), 0xc6);
    });

    test('ignores bit 5 of the written value', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x8000, 0x20);

      expect(mapper.registerAt(0x4105), 0);
    });

    test('forwards bits 3 and 4', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x8000, 0x18);

      expect(mapper.registerAt(0x4105), 0x18);
    });

    test(r'preserves $4105 bit 5', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x4105, 0x20)
        ..cpuWrite(0x8000, 0x06);

      expect(mapper.registerAt(0x4105), 0x26);
    });

    test(r'bit 6 swaps the PRG windows like $4105 bit 6', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x4107, 5)
        ..cpuWrite(0x8000, 0x40);

      expect(_prgBankAt(mapper, 0x8000), vtPrgBanks * 2 - 2);
      expect(_prgBankAt(mapper, 0xc000), 5);
    });

    test(r'bit 7 swaps the CHR windows like $4105 bit 7', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x2016, 6)
        ..cpuWrite(0x8000, 0x80);

      expect(_chrBankAt(mapper, 0x1000), 6);
      expect(_chrBankAt(mapper, 0x1400), 7);
    });
  });

  group(r'$8001', () {
    test(r'R0 writes $2016 and lands at PPU $0000 as an even/odd pair', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x8000, 0)
        ..cpuWrite(0x8001, 5);

      expect(mapper.registerAt(0x2016), 5);
      expect(_chrBankAt(mapper, 0x0000), 4);
      expect(_chrBankAt(mapper, 0x0400), 5);
    });

    test(r'R1 writes $2017 and lands at PPU $0800 as an even/odd pair', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x8000, 1)
        ..cpuWrite(0x8001, 9);

      expect(mapper.registerAt(0x2017), 9);
      expect(_chrBankAt(mapper, 0x0800), 8);
      expect(_chrBankAt(mapper, 0x0c00), 9);
    });

    for (var register = 2; register <= 5; register++) {
      final target = 0x2010 + register;
      final slot = 0x1000 + (register - 2) * 0x400;

      test('R$register writes \$${target.toRadixString(16).toUpperCase()} and '
          'lands at PPU \$${slot.toRadixString(16).toUpperCase()}', () {
        final (:nes, :mapper) = buildVt02();

        nes.bus
          ..cpuWrite(0x8000, register)
          ..cpuWrite(0x8001, 0x10 + register);

        expect(mapper.registerAt(target), 0x10 + register);
        expect(_chrBankAt(mapper, slot), 0x10 + register);
      });
    }

    test(r'R6 writes $4107 and lands at CPU $8000', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x8000, 6)
        ..cpuWrite(0x8001, 3);

      expect(mapper.registerAt(0x4107), 3);
      expect(_prgBankAt(mapper, 0x8000), 3);
    });

    test(r'R7 writes $4108 and lands at CPU $A000', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x8000, 7)
        ..cpuWrite(0x8001, 4);

      expect(mapper.registerAt(0x4108), 4);
      expect(_prgBankAt(mapper, 0xa000), 4);
    });

    test(r'uses an index written directly to $4105', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x4105, 6)
        ..cpuWrite(0x8001, 3);

      expect(_prgBankAt(mapper, 0x8000), 3);
    });
  });

  group(r'$A000', () {
    test('bit 0 selects the nametable arrangement', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0xa000, 0);
      mapper.ppuWrite(0x2000, 0x11);

      expect(mapper.ppuRead(0x2800), 0x11);

      nes.bus.cpuWrite(0xa000, 1);
      mapper.ppuWrite(0x2000, 0x22);

      expect(mapper.ppuRead(0x2400), 0x22);
    });

    test('forwards only bit 0', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0xa000, 0xff);

      expect(mapper.registerAt(0x4106), 0x01);
    });

    test(r'preserves the other $4106 bits', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x4106, 0xfe)
        ..cpuWrite(0xa000, 0x01);

      expect(mapper.registerAt(0x4106), 0xff);
    });
  });

  group(r'$A001', () {
    test('is not forwarded', () {
      final (:nes, :mapper) = buildVt02();
      final registers = [
        for (var address = 0x4100; address <= 0x411b; address++) address,
        for (var address = 0x2010; address <= 0x201a; address++) address,
      ];
      final before = [
        for (final address in registers) mapper.registerAt(address),
      ];

      nes.bus.cpuWrite(0xa001, 0xff);

      expect([
        for (final address in registers) mapper.registerAt(address),
      ], before);
    });
  });

  group('IRQ registers', () {
    test(r'$C000 lands in $4101', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0xc000, 0x42);

      expect(mapper.registerAt(0x4101), 0x42);
    });

    test(r'$C000 sets the preload, $C001 loads it and $E001 enables', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0xc000, 2)
        ..cpuWrite(0xe001, 0)
        ..cpuWrite(0xc001, 0);

      clockA12(mapper, nes, 2);

      expect(nes.cpu.irq & IrqSource.mapper.value, 0);

      clockA12(mapper, nes, 1);

      expect(nes.cpu.irq & IrqSource.mapper.value, isNot(0));
    });

    test(r'$E000 disables and acknowledges', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0xc000, 0)
        ..cpuWrite(0xe001, 0)
        ..cpuWrite(0xc001, 0);

      clockA12(mapper, nes, 1);

      expect(nes.cpu.irq & IrqSource.mapper.value, isNot(0));

      nes.bus.cpuWrite(0xe000, 0);

      expect(nes.cpu.irq & IrqSource.mapper.value, 0);

      clockA12(mapper, nes, 1);

      expect(nes.cpu.irq & IrqSource.mapper.value, 0);
    });
  });

  group('mirrored addresses', () {
    test('decode on A13-A15 and A0 like the MMC3', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x9ffe, 6)
        ..cpuWrite(0x9fff, 3)
        ..cpuWrite(0xbffe, 1)
        ..cpuWrite(0xdffe, 0x42);

      expect(_prgBankAt(mapper, 0x8000), 3);
      expect(mapper.registerAt(0x4106), 1);
      expect(mapper.registerAt(0x4101), 0x42);
    });
  });

  group('FWEN', () {
    test(r'$410B bit 3 stops forwarding', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x410b, 0x08)
        ..cpuWrite(0x8000, 6)
        ..cpuWrite(0x8001, 3)
        ..cpuWrite(0xa000, 1)
        ..cpuWrite(0xc000, 0x42);

      expect(mapper.registerAt(0x4105), 0);
      expect(mapper.registerAt(0x4107), 0);
      expect(mapper.registerAt(0x4106), 0);
      expect(mapper.registerAt(0x4101), 0);
      expect(_prgBankAt(mapper, 0x8000), 0);
    });

    test('clearing it resumes forwarding', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x410b, 0x08)
        ..cpuWrite(0x410b, 0x00)
        ..cpuWrite(0xc000, 0x42);

      expect(mapper.registerAt(0x4101), 0x42);
    });
  });
}
