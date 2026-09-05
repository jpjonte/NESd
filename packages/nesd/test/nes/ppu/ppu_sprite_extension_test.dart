import 'package:flutter_test/flutter_test.dart';

import 'four_bpp_harness.dart';

void main() {
  group('sprite address extension', () {
    test('OAM byte 2 bits 2-4 select the EVA bank', () {
      final nes = buildNes(buildEvaRom());

      nes.bus.cpuWrite(0x2010, 0x08); // SPEXTEN, 2bpp

      for (var i = 1; i < 4; i++) {
        nes.bus.ppuWrite(0x3f10 + i, 0x20 + i);
      }

      nes.ppu.oam.fillRange(0, 256, 0xff);
      nes.ppu.oam.setAll(0, [9, 0, 0x0c, 64]); // EVA 3

      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      // bank 3 -> lit column at xOffset 3, pattern value 1
      expect(pixelAt(nes.ppu, 64 + 3, 10), nes.ppu.paletteLut[0x11]);
    });

    test('two sprites on one line use their own EVA', () {
      final nes = buildNes(buildEvaRom());

      nes.bus.cpuWrite(0x2010, 0x08);

      for (var i = 1; i < 4; i++) {
        nes.bus.ppuWrite(0x3f10 + i, 0x20 + i);
      }

      nes.ppu.oam.fillRange(0, 256, 0xff);
      nes.ppu.oam.setAll(0, [
        9, 0, 0x04, 32, // sprite 0: EVA 1
        9, 0, 0x14, 96, // sprite 1: EVA 5
      ]);

      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      expect(pixelAt(nes.ppu, 32 + 1, 10), nes.ppu.paletteLut[0x11]);
      expect(pixelAt(nes.ppu, 96 + 5, 10), nes.ppu.paletteLut[0x11]);
    });

    test('4bpp sprites fetch through the EVA space', () {
      final nes = buildNes(buildEvaRom(fourBpp: true));

      nes.bus.cpuWrite(0x2010, 0x0c); // SP16EN | SPEXTEN

      for (var i = 1; i < 16; i++) {
        nes.bus.ppuWrite(0x3f10 + i, 0x20 + i);
      }

      nes.ppu.oam.fillRange(0, 256, 0xff);
      nes.ppu.oam.setAll(0, [9, 0, 0x08, 64]); // EVA 2

      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      expect(pixelAt(nes.ppu, 64 + 2, 10), nes.ppu.paletteLut[0x11]);
    });
  });
}
