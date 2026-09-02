import 'package:flutter_test/flutter_test.dart';

import 'four_bpp_harness.dart';

void main() {
  group('background address extension', () {
    test('attribute bits select the EVA bank and are palette-inert', () {
      final nes = buildNes(buildEvaRom());

      nes.bus.cpuWrite(0x2010, 0x10); // BKEXTEN, 2bpp
      nes.bus.ppuWrite(0x23c0, 0x01); // attr 1, top-left quadrant

      for (var i = 0; i < 4; i++) {
        nes.bus.ppuWrite(0x3f00 + i, 0x10 + i);
        nes.bus.ppuWrite(0x3f04 + i, 0x20 + i); // attr-1 palette: unused
      }

      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      expect(pixelAt(nes.ppu, 1, 10), nes.ppu.paletteLut[1]);
      expect(pixelAt(nes.ppu, 0, 10), nes.ppu.paletteLut[0]);
      expect(pixelAt(nes.ppu, 2, 10), nes.ppu.paletteLut[0]);
    });

    test('BKPAGE supplies EVA bit 2 while EVA12S is clear', () {
      final nes = buildNes(buildEvaRom());

      nes.bus.cpuWrite(0x2010, 0x10);
      nes.bus.cpuWrite(0x2018, 0x08); // BKPAGE = 1
      nes.bus.ppuWrite(0x23c0, 0x01); // attr 1

      for (var i = 0; i < 4; i++) {
        nes.bus.ppuWrite(0x3f00 + i, 0x10 + i);
      }

      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      // EVA = 4 | 1 = 5 -> lit column x = 5
      expect(pixelAt(nes.ppu, 5, 10), nes.ppu.paletteLut[1]);
      expect(pixelAt(nes.ppu, 1, 10), nes.ppu.paletteLut[0]);
    });

    test('HV supplies EVA bit 2 while EVA12S is set', () {
      final nes = buildNes(buildEvaRom());

      nes.bus.cpuWrite(0x2010, 0x10);
      nes.bus.cpuWrite(0x2011, 0x01); // EVA12S
      nes.bus.cpuWrite(0x2018, 0x08); // BKPAGE set but now inert
      nes.bus.cpuWrite(0x4106, 0x01); // HV = 1

      for (var i = 0; i < 4; i++) {
        nes.bus.ppuWrite(0x3f00 + i, 0x10 + i);
      }

      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      // EVA = 4 | attr 0 = 4 -> lit column x = 4
      expect(pixelAt(nes.ppu, 4, 10), nes.ppu.paletteLut[1]);
    });

    test('4bpp backgrounds fetch through the EVA space', () {
      final nes = buildNes(buildEvaRom(fourBpp: true));

      nes.bus.cpuWrite(0x2010, 0x12); // BK16EN | BKEXTEN
      nes.bus.ppuWrite(0x23c0, 0x01); // attr 1 -> EVA 1 -> 2 KiB bank 1

      for (var i = 0; i < 16; i++) {
        nes.bus.ppuWrite(0x3f00 + i, i);
      }

      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      expect(pixelAt(nes.ppu, 1, 10), nes.ppu.paletteLut[1]);
      expect(pixelAt(nes.ppu, 0, 10), nes.ppu.paletteLut[0]);
    });
  });
}
