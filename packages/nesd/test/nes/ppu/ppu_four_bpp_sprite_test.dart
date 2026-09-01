import 'package:flutter_test/flutter_test.dart';

import 'ppu_four_bpp_bg_test.dart';

void main() {
  group('4bpp sprites', () {
    test('render through the sprite half of the palette', () {
      final nes = buildNes(buildFourBppRom());

      nes.bus.cpuWrite(0x2010, 0x04); // sprites 4bpp, background 2bpp

      for (var i = 1; i < 16; i++) {
        nes.bus.ppuWrite(0x3f10 + i, 0x20 + i);
      }

      nes.ppu.oam.fillRange(0, 256, 0xff);
      nes.ppu.oam.setAll(0, [9, 0, 0x00, 64]); // y=9, tile 0, front, x=64

      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      for (var xOffset = 0; xOffset < 7; xOffset++) {
        expect(
          pixelAt(nes.ppu, 64 + xOffset, 10),
          nes.ppu.paletteLut[0x10 | expectedPattern[xOffset]],
          reason: 'xOffset=$xOffset',
        );
      }
    });

    test('a behind-background 4bpp sprite loses to opaque background', () {
      final nes = buildNes(buildFourBppRom());

      nes.bus.cpuWrite(0x2010, 0x06); // both 4bpp

      for (var i = 0; i < 16; i++) {
        nes.bus.ppuWrite(0x3f00 + i, i);
        if (i > 0) {
          nes.bus.ppuWrite(0x3f10 + i, 0x20 + i);
        }
      }

      nes.ppu.oam.fillRange(0, 256, 0xff);
      nes.ppu.oam.setAll(0, [9, 0, 0x20, 64]); // priority: behind

      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      expect(pixelAt(nes.ppu, 64, 10), nes.ppu.paletteLut[7]);
      expect(pixelAt(nes.ppu, 64 + 7, 10), nes.ppu.paletteLut[0]);
    });

    test('sprite 0 hits background pixels with zero low bits', () {
      final nes = buildNes(buildFourBppRom());

      nes.bus.cpuWrite(0x2010, 0x06);

      nes.ppu.oam.fillRange(0, 256, 0xff);
      nes.ppu.oam.setAll(0, [9, 0, 0x00, 3]);

      nes.bus.cpuWrite(0x2001, 0x1e);

      while (nes.ppu.frames < 1 || nes.ppu.scanline < 60) {
        nes.step();
        nes.apu.sampleIndex = 0;
      }

      expect((nes.ppu.PPUSTATUS >> 6) & 1, 1);
    });

    test('2bpp sprites still render while the background is 4bpp', () {
      final nes = buildNes(buildFourBppRom());

      nes.bus.cpuWrite(0x2010, 0x02); // background 4bpp, sprites 2bpp

      for (var i = 1; i < 4; i++) {
        nes.bus.ppuWrite(0x3f10 + i, 0x30 + i);
      }

      nes.ppu.oam.fillRange(0, 256, 0xff);
      nes.ppu.oam.setAll(0, [9, 0, 0x00, 64]);

      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      const expected2bpp = [3, 2, 1, 0, 3, 2, 1, 0];

      for (var xOffset = 0; xOffset < 8; xOffset++) {
        final pattern = expected2bpp[xOffset];

        if (pattern == 0) {
          continue; // background shows through; covered above
        }

        expect(
          pixelAt(nes.ppu, 64 + xOffset, 10),
          nes.ppu.paletteLut[0x10 | pattern],
          reason: 'xOffset=$xOffset',
        );
      }
    });
  });
}
