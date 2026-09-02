import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/vt/vt02.dart';
import 'package:nesd/nes/nes.dart';

import 'vt02_harness.dart';

int evaBankAt2bpp(VT02 mapper, int eva, int address) =>
    mapper.eva2bppRead(eva, address) |
    (mapper.eva2bppRead(eva, address + 1) << 8);

int evaBankAt4bpp(VT02 mapper, int eva, int address) =>
    mapper.eva4bppRead(eva, address) |
    (mapper.eva4bppRead(eva, address + 1) << 8);

int ppuEvaBankAt2bpp(NES nes, int eva, int address) =>
    nes.ppu.readEva2bpp(eva, address) |
    (nes.ppu.readEva2bpp(eva, address + 1) << 8);

void main() {
  group('mapPpuEva2bpp', () {
    test('maps 1 KiB pages per EVA slot', () {
      final (:nes, :mapper) = buildVt02(chrPages: 64);

      mapper.mapPpuEva2bpp(
        5,
        0x0000,
        0x03ff,
        37,
        source: nes.bus.cartridge.chrRom,
      );

      expect(evaBankAt2bpp(mapper, 5, 0x0000), 37);
    });

    test('pushes the mapping to the PPU', () {
      final (:nes, :mapper) = buildVt02(chrPages: 64);

      mapper.mapPpuEva2bpp(
        2,
        0x0400,
        0x07ff,
        9,
        source: nes.bus.cartridge.chrRom,
      );

      expect(ppuEvaBankAt2bpp(nes, 2, 0x0400), 9);
    });

    test('unmapped EVA blocks read zero', () {
      final (:nes, :mapper) = buildVt02(chrPages: 64);

      expect(mapper.eva2bppRead(0, 0x0000), 0);
      expect(nes.ppu.readEva2bpp(7, 0x1c00), 0);
    });

    test('an empty source clears the mapping', () {
      final (:nes, :mapper) = buildVt02(chrPages: 64);

      mapper.mapPpuEva2bpp(
        1,
        0x0000,
        0x03ff,
        3,
        source: nes.bus.cartridge.chrRom,
      );
      mapper.mapPpuEva2bpp(1, 0x0000, 0x03ff, 0, source: Uint8List(0));

      expect(mapper.eva2bppRead(1, 0x0000), 0);
      expect(nes.ppu.readEva2bpp(1, 0x0000), 0);
    });
  });

  group('mapPpuEva4bpp', () {
    test('maps 2 KiB pages onto 1 KiB CHR stamps', () {
      final (:nes, :mapper) = buildVt02(chrPages: 64);

      mapper.mapPpuEva4bpp(
        5,
        0x0000,
        0x07ff,
        37,
        source: nes.bus.cartridge.chrRom,
      );

      expect(evaBankAt4bpp(mapper, 5, 0x0000), 74);
      expect(evaBankAt4bpp(mapper, 5, 0x0400), 75);
    });

    test('wraps pages beyond the source', () {
      final (:nes, :mapper) = buildVt02(chrPages: 1); // 4 pages

      mapper.mapPpuEva4bpp(
        0,
        0x0000,
        0x07ff,
        5,
        source: nes.bus.cartridge.chrRom,
      );

      expect(evaBankAt4bpp(mapper, 0, 0x0000), 2); // page 5 % 4 = 1
    });
  });
}
