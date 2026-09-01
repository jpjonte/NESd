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
}
