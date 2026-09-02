import 'package:flutter_test/flutter_test.dart';

import 'four_bpp_harness.dart';

const left = [3, 2, 1, 0, 3, 2, 1, 0];
const right = [1, 1, 1, 1, 0, 0, 0, 0];

void main() {
  group('16-pixel sprites', () {
    test('planes 2/3 draw the right half', () {
      final nes = buildNes(buildFourBppRom());

      nes.bus.cpuWrite(0x2010, 0x05); // SP16EN | PIX16EN

      for (var i = 1; i < 4; i++) {
        nes.bus.ppuWrite(0x3f10 + i, 0x20 + i);
      }

      nes.bus.ppuWrite(0x3f00, 0x0f);

      nes.ppu.oam.fillRange(0, 256, 0xff);
      nes.ppu.oam.setAll(0, [9, 0, 0x00, 64]);

      nes.bus.cpuWrite(0x2001, 0x14);

      runFrames(nes, 2);

      for (var i = 0; i < 16; i++) {
        final value = i < 8 ? left[i] : right[i - 8];

        if (value == 0) {
          expect(
            pixelAt(nes.ppu, 64 + i, 10),
            nes.ppu.paletteLut[0],
            reason: 'i=$i',
          );
        } else {
          expect(
            pixelAt(nes.ppu, 64 + i, 10),
            nes.ppu.paletteLut[0x10 | value],
            reason: 'i=$i',
          );
        }
      }
    });

    test('horizontal flip mirrors the full sixteen pixels', () {
      final nes = buildNes(buildFourBppRom());

      nes.bus.cpuWrite(0x2010, 0x05);

      for (var i = 1; i < 4; i++) {
        nes.bus.ppuWrite(0x3f10 + i, 0x20 + i);
      }

      nes.ppu.oam.fillRange(0, 256, 0xff);
      nes.ppu.oam.setAll(0, [9, 0, 0x40, 64]); // flip H

      nes.bus.cpuWrite(0x2001, 0x14); // sprites only

      runFrames(nes, 2);

      for (var i = 0; i < 16; i++) {
        final mirrored = 15 - i;
        final value = mirrored < 8 ? left[mirrored] : right[mirrored - 8];

        if (value != 0) {
          expect(
            pixelAt(nes.ppu, 64 + i, 10),
            nes.ppu.paletteLut[0x10 | value],
            reason: 'i=$i',
          );
        }
      }
    });

    test('a behind-background right half loses to opaque background', () {
      final nes = buildNes(buildFourBppRom());

      nes.bus.cpuWrite(0x2010, 0x07); // BK16EN | SP16EN | PIX16EN

      for (var i = 0; i < 4; i++) {
        nes.bus.ppuWrite(0x3f00 + i, i);
        nes.bus.ppuWrite(0x3f20 + i, 0x10 + i);
      }

      nes.ppu.oam.fillRange(0, 256, 0xff);
      nes.ppu.oam.setAll(0, [9, 0, 0x20, 64]); // priority: behind

      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      expect(pixelAt(nes.ppu, 64 + 8, 10), isNot(nes.ppu.paletteLut[0x11]));
    });

    test('the right half triggers sprite 0 hits', () {
      final nes = buildNes(buildFourBppRom(stampTileOne: true));

      nes.bus.cpuWrite(0x2010, 0x07);

      nes.ppu.oam.fillRange(0, 256, 0xff);
      nes.ppu.oam.setAll(0, [9, 1, 0x00, 3]);

      nes.bus.cpuWrite(0x2001, 0x1e);

      while (nes.ppu.frames < 1 || nes.ppu.scanline < 60) {
        nes.step();
        nes.apu.sampleIndex = 0;
      }

      expect((nes.ppu.PPUSTATUS >> 6) & 1, 1);
    });

    test('the right half clips at x = 255', () {
      final nes = buildNes(buildFourBppRom());

      nes.bus.cpuWrite(0x2010, 0x05);

      for (var i = 1; i < 4; i++) {
        nes.bus.ppuWrite(0x3f10 + i, 0x20 + i);
      }

      nes.ppu.oam.fillRange(0, 256, 0xff);
      nes.ppu.oam.setAll(0, [9, 0, 0x00, 250]);

      nes.bus.cpuWrite(0x2001, 0x14); // sprites only

      runFrames(nes, 2);

      expect(pixelAt(nes.ppu, 250, 10), nes.ppu.paletteLut[0x13]);
      expect(pixelAt(nes.ppu, 0, 10), nes.ppu.paletteLut[0]);
    });
  });
}
