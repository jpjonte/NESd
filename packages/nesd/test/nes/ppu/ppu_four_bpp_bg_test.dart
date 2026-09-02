import 'package:flutter_test/flutter_test.dart';

import 'four_bpp_harness.dart';

void main() {
  group('4bpp background', () {
    test('renders 4-bit pixels through the low palette entries', () {
      final nes = buildNes(buildFourBppRom());

      nes.bus.cpuWrite(0x2010, 0x02);

      for (var i = 0; i < 16; i++) {
        nes.bus.ppuWrite(0x3f00 + i, i);
      }

      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      for (var x = 0; x < 8; x++) {
        expect(
          pixelAt(nes.ppu, x, 10),
          nes.ppu.paletteLut[expectedPattern[x]],
          reason: 'x=$x',
        );
      }
    });

    test('attribute bits land at index bits 5-6', () {
      final nes = buildNes(buildFourBppRom());

      nes.bus.cpuWrite(0x2010, 0x02);
      nes.bus.ppuWrite(0x23c0, 0x01); // attr 1 for the top-left quadrant

      for (var i = 0; i < 16; i++) {
        nes.bus.ppuWrite(0x3f20 + i, 0x10 + i);
      }

      nes.bus.ppuWrite(0x3f00, 0x00);
      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      for (var x = 0; x < 8; x++) {
        final pattern = expectedPattern[x];
        final index = pattern == 0 ? 0 : 0x20 | pattern;

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

      for (var i = 0; i < 16; i++) {
        nes.bus.ppuWrite(0x3f00 + i, i);
      }

      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      for (var x = 0; x < 8; x++) {
        expect(
          pixelAt(nes.ppu, x, 10),
          nes.ppu.paletteLut[expectedPattern[x]],
          reason: 'x=$x',
        );
      }
    });
  });
}
