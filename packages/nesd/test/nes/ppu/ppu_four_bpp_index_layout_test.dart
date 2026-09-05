import 'package:flutter_test/flutter_test.dart';

import 'four_bpp_harness.dart';

void main() {
  group('4bpp index layout', () {
    test('background plane 3 lands at bit 6, attribute at bits 2-3', () {
      final nes = buildNes(
        buildFourBppRom(planeRows: const [0x00, 0x00, 0x00, 0xf0]),
      );

      nes.bus.cpuWrite(0x2010, 0x02);
      nes.bus.ppuWrite(0x23c0, 0x01); // attr 1, top-left quadrant

      nes.bus.ppuWrite(0x3f44, 0x21); // plane3<<6 | attr<<2
      nes.bus.ppuWrite(0x3f28, 0x16); // attr<<5 | pattern 8

      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      expect(pixelAt(nes.ppu, 0, 10), nes.ppu.paletteLut[0x44]);
      expect(pixelAt(nes.ppu, 0, 10), isNot(nes.ppu.paletteLut[0x28]));
      expect(pixelAt(nes.ppu, 4, 10), nes.ppu.paletteLut[0]);
    });

    test('sprite plane 3 lands at bit 6, palette at bits 2-3', () {
      final nes = buildNes(
        buildFourBppRom(planeRows: const [0x00, 0x00, 0x00, 0xf0]),
      );

      nes.bus.cpuWrite(0x2010, 0x04);

      nes.bus.ppuWrite(0x3f54, 0x2a); // 0x10 | plane3<<6 | palette<<2
      nes.bus.ppuWrite(0x3f38, 0x17); // 0x10 | palette<<5 | pattern 8

      nes.ppu.oam.fillRange(0, 256, 0xff);
      nes.ppu.oam.setAll(0, [9, 0, 0x01, 64]); // palette 1

      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      expect(pixelAt(nes.ppu, 64, 10), nes.ppu.paletteLut[0x54]);
      expect(pixelAt(nes.ppu, 64, 10), isNot(nes.ppu.paletteLut[0x38]));
    });
    test('background plane 2 lands at bit 5', () {
      final nes = buildNes(
        buildFourBppRom(planeRows: const [0x00, 0x00, 0xf0, 0x00]),
      );

      nes.bus.cpuWrite(0x2010, 0x02);

      nes.bus.ppuWrite(0x3f20, 0x27); // plane2<<5
      nes.bus.ppuWrite(0x3f40, 0x18); // plane3<<6: must stay untouched

      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      expect(pixelAt(nes.ppu, 0, 10), nes.ppu.paletteLut[0x20]);
      expect(pixelAt(nes.ppu, 0, 10), isNot(nes.ppu.paletteLut[0x40]));
    });
  });
}
