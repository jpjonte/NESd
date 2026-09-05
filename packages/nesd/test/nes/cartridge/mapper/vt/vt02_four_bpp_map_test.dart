import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/vt/vt02.dart';
import 'package:nesd/nes/nes.dart';

import 'vt02_harness.dart';

int bankAt4bpp(VT02 mapper, int address) =>
    mapper.fourBppRead(address) | (mapper.fourBppRead(address + 1) << 8);

int ppuBankAt4bpp(NES nes, int address) =>
    nes.ppu.readFourBpp(address) | (nes.ppu.readFourBpp(address + 1) << 8);

void main() {
  group('mapPpu4bpp', () {
    test('maps 2 KiB pages onto 1 KiB CHR stamps', () {
      final (:nes, :mapper) = buildVt02();

      mapper.mapPpu4bpp(0x0000, 0x07ff, 3, source: nes.bus.cartridge.chrRom);

      // 2 KiB page 3 starts at the 1 KiB stamp for bank 6.
      expect(bankAt4bpp(mapper, 0x0000), 6);
      expect(bankAt4bpp(mapper, 0x0400), 7);
    });

    test('pushes the mapping to the PPU block table', () {
      final (:nes, :mapper) = buildVt02();

      mapper.mapPpu4bpp(0x0800, 0x0fff, 5, source: nes.bus.cartridge.chrRom);

      expect(ppuBankAt4bpp(nes, 0x0800), 10);
      expect(ppuBankAt4bpp(nes, 0x0c00), 11);
    });

    test('wraps pages beyond the source', () {
      final (:nes, :mapper) = buildVt02(chrPages: 1); // 8 KiB = 4 pages

      mapper.mapPpu4bpp(0x0000, 0x07ff, 5, source: nes.bus.cartridge.chrRom);

      expect(bankAt4bpp(mapper, 0x0000), 2); // page 5 % 4 = page 1
    });

    test('an empty source reads as zero', () {
      final (:nes, :mapper) = buildVt02();

      mapper.mapPpu4bpp(0x0000, 0x07ff, 0, source: Uint8List(0));

      expect(mapper.fourBppRead(0x0000), 0);
      expect(nes.ppu.readFourBpp(0x0000), 0);
    });
  });

  group(r'$2010 video mode', () {
    test('pushes the mode bits to the PPU', () {
      final (:nes, mapper: _) = buildVt02();

      nes.bus.cpuWrite(0x2010, 0x42);

      expect(nes.ppu.bgFourBpp, isTrue);
      expect(nes.ppu.spriteFourBpp, isFalse);
      expect(nes.ppu.wideVideoBus, isTrue);
    });

    test('enabling 4bpp maps the pattern space at 2 KiB granularity', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x2016, 4);
      nes.bus.cpuWrite(0x2012, 5);
      nes.bus.cpuWrite(0x2010, 0x02);

      expect(bankAt4bpp(mapper, 0x0000), 8); // RV4 pair, 2 KiB page 4
      expect(bankAt4bpp(mapper, 0x2000), 10); // RV0 slot, 2 KiB page 5
      expect(ppuBankAt4bpp(nes, 0x0000), 8);
    });

    test('bank writes keep the 4bpp table current while active', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x2010, 0x04);
      nes.bus.cpuWrite(0x2017, 6);

      expect(bankAt4bpp(mapper, 0x1000), 12);
    });

    test(r'$4105 bit 7 swaps the pattern tables in the 4bpp space', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x2010, 0x02);
      nes.bus.cpuWrite(0x2016, 2);
      nes.bus.cpuWrite(0x4105, 0x80);

      expect(bankAt4bpp(mapper, 0x2000), 4); // RV4 pair now above $1000
    });

    test('the 4bpp table stays empty while both modes are 2bpp', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x2016, 4);

      expect(mapper.fourBppRead(0x0000), 0);
      expect(nes.ppu.readFourBpp(0x0000), 0);
    });

    test(r'the $201A middle bank masks the 4bpp inner bank', () {
      final (:nes, :mapper) = buildVt02(chrPages: 64); // 512 KiB

      nes.bus.cpuWrite(0x2010, 0x02);
      nes.bus.cpuWrite(0x2016, 0x07);
      nes.bus.cpuWrite(0x201a, 0xc2);

      expect(bankAt4bpp(mapper, 0x0000), 0x18c);
    });

    test('OneBus images map the 4bpp space over PRG-ROM', () {
      final (:nes, :mapper) = buildVt02(chrPages: 0);

      nes.bus.cpuWrite(0x2016, 0x10);
      nes.bus.cpuWrite(0x2010, 0x02);

      expect(bankAt4bpp(mapper, 0x0000), 4);
    });

    test('reset clears the mode', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x2010, 0x46);
      mapper.reset();

      expect(nes.ppu.bgFourBpp, isFalse);
      expect(nes.ppu.wideVideoBus, isFalse);
    });

    test('restoring mapper state re-pushes mode and mapping', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x2016, 4);
      nes.bus.cpuWrite(0x2010, 0x06);

      final state = mapper.state;
      final (nes: nes2, mapper: mapper2) = buildVt02();

      mapper2.state = state;

      expect(nes2.ppu.bgFourBpp, isTrue);
      expect(nes2.ppu.spriteFourBpp, isTrue);
      expect(bankAt4bpp(mapper2, 0x0000), 8);
    });

    test('pushes the extension bits to the PPU', () {
      final (:nes, mapper: _) = buildVt02();

      nes.bus.cpuWrite(0x2010, 0x19); // BKEXTEN | SPEXTEN | PIX16EN

      expect(nes.ppu.bgExtension, isTrue);
      expect(nes.ppu.spriteExtension, isTrue);
      expect(nes.ppu.spriteSixteenPixels, isTrue);
    });

    test(r'EVA12S selects the bgEvaBit2 source', () {
      final (:nes, mapper: _) = buildVt02();

      nes.bus.cpuWrite(0x2018, 0x08); // BKPAGE = 1

      expect(nes.ppu.bgEvaBit2, 1);

      nes.bus.cpuWrite(0x2011, 0x01); // EVA12S = 1 -> $4106.0

      expect(nes.ppu.bgEvaBit2, 0);

      nes.bus.cpuWrite(0x4106, 0x01);

      expect(nes.ppu.bgEvaBit2, 1);
    });

    test(r'$2018 pushes VRWB', () {
      final (:nes, mapper: _) = buildVt02();

      nes.bus.cpuWrite(0x2018, 0x05);

      expect(nes.ppu.vrwb, 5);
    });

    test('reset clears the extension state', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x2010, 0x19);
      nes.bus.cpuWrite(0x2018, 0x0f);
      mapper.reset();

      expect(nes.ppu.bgExtension, isFalse);
      expect(nes.ppu.spriteExtension, isFalse);
      expect(nes.ppu.spriteSixteenPixels, isFalse);
      expect(nes.ppu.bgEvaBit2, 0);
      expect(nes.ppu.vrwb, 0);
    });

    test('restoring mapper state re-pushes extension state and banks', () {
      final (:nes, :mapper) = buildVt02(chrPages: 64);

      nes.bus.cpuWrite(0x2016, 4);
      nes.bus.cpuWrite(0x2011, 0x01);
      nes.bus.cpuWrite(0x4106, 0x01);
      nes.bus.cpuWrite(0x2018, 0x03);
      nes.bus.cpuWrite(0x2010, 0x18);

      final state = mapper.state;
      final (nes: nes2, mapper: mapper2) = buildVt02(chrPages: 64);

      mapper2.state = state;

      expect(nes2.ppu.bgExtension, isTrue);
      expect(nes2.ppu.spriteExtension, isTrue);
      expect(nes2.ppu.bgEvaBit2, 1);
      expect(nes2.ppu.vrwb, 3);
      expect(
        mapper2.eva2bppRead(5, 0x0000) | (mapper2.eva2bppRead(5, 0x0001) << 8),
        37,
      );
    });
  });
}
