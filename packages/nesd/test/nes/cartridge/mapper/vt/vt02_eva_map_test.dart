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

  group('VT02 EVA banking', () {
    test('installs bank | eva for each slot while BKEXTEN is set', () {
      final (:nes, :mapper) = buildVt02(chrPages: 64);

      nes.bus.cpuWrite(0x2016, 4); // RV4: slot0 inner 4, slot1 inner 5
      nes.bus.cpuWrite(0x2010, 0x10); // BKEXTEN

      // slot 0: (4 << 3) | eva
      expect(evaBankAt2bpp(mapper, 0, 0x0000), 32);
      expect(evaBankAt2bpp(mapper, 5, 0x0000), 37);
      // slot 1: (5 << 3) | eva
      expect(evaBankAt2bpp(mapper, 2, 0x0400), 42);
    });

    test('SPEXTEN alone also installs the tables', () {
      final (:nes, :mapper) = buildVt02(chrPages: 64);

      nes.bus.cpuWrite(0x2010, 0x08); // SPEXTEN
      nes.bus.cpuWrite(0x2012, 3); // RV0: slot 4

      expect(evaBankAt2bpp(mapper, 1, 0x1000), 25); // (3 << 3) | 1
    });

    test('the 4bpp view carries the same bank numbers', () {
      final (:nes, :mapper) = buildVt02(chrPages: 64);

      nes.bus.cpuWrite(0x2016, 4);
      nes.bus.cpuWrite(0x2010, 0x10);

      // bank 37 in 2 KiB units = stamp 74
      expect(evaBankAt4bpp(mapper, 5, 0x0000), 74);
    });

    test('the tables stay empty while neither extension is set', () {
      final (:nes, :mapper) = buildVt02(chrPages: 64);

      nes.bus.cpuWrite(0x2016, 4);
      nes.bus.cpuWrite(0x2010, 0x06); // 4bpp only, no extension

      expect(mapper.eva2bppRead(0, 0x0000), 0);
    });

    test('the intermediate bank does not affect EVA banks', () {
      final (:nes, :mapper) = buildVt02(chrPages: 64);

      nes.bus.cpuWrite(0x2010, 0x10);
      nes.bus.cpuWrite(0x2018, 0x70); // VA18-20 = 7

      expect(evaBankAt2bpp(mapper, 0, 0x0000), 0);
      expect(evaBankAt2bpp(mapper, 3, 0x0000), 3);
    });

    test(r'the $201A middle bank masks in above the EVA bits', () {
      final (:nes, :mapper) = buildVt02(chrPages: 64);

      nes.bus.cpuWrite(0x2010, 0x10);
      nes.bus.cpuWrite(0x2016, 0x07);
      nes.bus.cpuWrite(0x201a, 0xc2); // mask 0x3f, middle 0xc0

      // ((0x06 | 0xc0) << 3) | eva = 0x630 | eva; 0x630 % 512 stamps
      expect(evaBankAt2bpp(mapper, 1, 0x0000), (0x630 | 1) % 512);
    });

    test('COMR7 swaps the pattern-table halves in the EVA space', () {
      final (:nes, :mapper) = buildVt02(chrPages: 64);

      nes.bus.cpuWrite(0x2010, 0x10);
      nes.bus.cpuWrite(0x2016, 2);
      nes.bus.cpuWrite(0x4105, 0x80);

      // RV4 pair now above $1000: slot 4 -> (2 << 3) | eva
      expect(evaBankAt2bpp(mapper, 0, 0x1000), 16);
    });

    test('the outer bank lands at bit 11', () {
      final (:nes, :mapper) = buildVt02(chrPages: 512);

      nes.bus.cpuWrite(0x2010, 0x10);
      nes.bus.cpuWrite(0x4100, 0x01); // outer 1

      expect(evaBankAt2bpp(mapper, 1, 0x0000), 2048 | 1);
    });

    test('bank writes keep the EVA tables current', () {
      final (:nes, :mapper) = buildVt02(chrPages: 64);

      nes.bus.cpuWrite(0x2010, 0x10);
      nes.bus.cpuWrite(0x2016, 6);

      expect(evaBankAt2bpp(mapper, 0, 0x0000), 48); // (6 << 3)
    });

    test('OneBus images install the EVA space over PRG-ROM', () {
      final (:nes, :mapper) = buildVt02(chrPages: 0);

      nes.bus.cpuWrite(0x2016, 0x02);
      nes.bus.cpuWrite(0x2010, 0x10);

      expect(evaBankAt2bpp(mapper, 0, 0x0000), 2);
    });
  });
}
