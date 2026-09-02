import 'package:flutter_test/flutter_test.dart';

import 'four_bpp_harness.dart';

void main() {
  group('4bpp background', () {
    test('renders 4bpp pixels with planes 2/3 at index bits 5-6', () {
      final nes = buildNes(buildFourBppRom());

      nes.bus.cpuWrite(0x2010, 0x02);

      for (var i = 0; i < 4; i++) {
        nes.bus.ppuWrite(0x3f00 + i, i);
        nes.bus.ppuWrite(0x3f20 + i, 0x10 + i);
      }

      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      for (var x = 0; x < 8; x++) {
        expect(
          pixelAt(nes.ppu, x, 10),
          nes.ppu.paletteLut[expectedIndices[x]],
          reason: 'x=$x',
        );
      }
    });

    test('attribute bits land at index bits 2-3', () {
      final nes = buildNes(buildFourBppRom());

      nes.bus.cpuWrite(0x2010, 0x02);
      nes.bus.ppuWrite(0x23c0, 0x01); // attr 1 for the top-left quadrant

      for (var i = 4; i < 8; i++) {
        nes.bus.ppuWrite(0x3f00 + i, i);
        nes.bus.ppuWrite(0x3f20 + i, 0x10 + i);
      }

      nes.bus.ppuWrite(0x3f00, 0x00);
      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      for (var x = 0; x < 8; x++) {
        final pix = expectedIndices[x];
        final index = pix == 0 ? 0 : pix | 0x04;

        expect(
          pixelAt(nes.ppu, x, 10),
          nes.ppu.paletteLut[index],
          reason: 'x=$x',
        );
      }
    });

    test('the 16-bit-bus layout renders identically', () {
      final nes = buildNes(buildFourBppRom(wideLayout: true));

      nes.bus.cpuWrite(0x2010, 0x42);

      for (var i = 0; i < 4; i++) {
        nes.bus.ppuWrite(0x3f00 + i, i);
        nes.bus.ppuWrite(0x3f20 + i, 0x10 + i);
      }

      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      for (var x = 0; x < 8; x++) {
        expect(
          pixelAt(nes.ppu, x, 10),
          nes.ppu.paletteLut[expectedIndices[x]],
          reason: 'x=$x',
        );
      }
    });
  });
}
