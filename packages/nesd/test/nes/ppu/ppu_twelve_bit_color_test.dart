import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/palette/vt_palette.dart';

import '../cartridge/mapper/vt/vt02_harness.dart';

void main() {
  group('VT 12-bit color', () {
    test('COLCOMP combines both palette halves through the VT decode', () {
      final (:nes, mapper: _) = buildVt02();

      nes.bus.ppuWrite(0x3f27, 0x15);
      nes.bus.ppuWrite(0x3fa7, 0x2a);

      nes.bus.cpuWrite(0x2010, 0x80);

      expect(nes.ppu.paletteLut[0x27], vtPalette[0x15 | (0x2a << 6)]);
    });

    test('high-half writes refresh the LUT while COLCOMP is set', () {
      final (:nes, mapper: _) = buildVt02();

      nes.bus.cpuWrite(0x2010, 0x80);

      nes.bus.ppuWrite(0x3f27, 0x15);
      nes.bus.ppuWrite(0x3fa7, 0x2a);

      expect(nes.ppu.paletteLut[0x27], vtPalette[0x15 | (0x2a << 6)]);
    });

    test('clearing COLCOMP restores the 2C02 decode', () {
      final (:nes, mapper: _) = buildVt02();

      nes.bus.ppuWrite(0x3f27, 0x15);
      nes.bus.ppuWrite(0x3fa7, 0x2a);

      nes.bus.cpuWrite(0x2010, 0x80);

      expect(nes.ppu.paletteLut[0x27], isNot(nes.ppu.systemPalette[0x15]));

      nes.bus.cpuWrite(0x2010, 0x00);

      expect(nes.ppu.paletteLut[0x27], nes.ppu.systemPalette[0x15]);
    });

    test('backdrop high-half write refreshes the sprite-half mirror', () {
      final (:nes, mapper: _) = buildVt02();

      nes.bus.cpuWrite(0x2010, 0x80);

      nes.bus.ppuWrite(0x3f00, 0x21);
      nes.bus.ppuWrite(0x3f80, 0x0f);

      expect(nes.ppu.paletteLut[0x00], vtPalette[0x21 | (0x0f << 6)]);
      expect(nes.ppu.paletteLut[0x10], nes.ppu.paletteLut[0x00]);
    });

    test('greyscale and emphasis leave the 12-bit decode alone', () {
      final (:nes, mapper: _) = buildVt02();

      nes.bus.cpuWrite(0x2010, 0x80);

      nes.bus.ppuWrite(0x3f27, 0x15);
      nes.bus.ppuWrite(0x3fa7, 0x2a);

      nes.bus.cpuWrite(0x2001, 0xe1);

      expect(nes.ppu.paletteLut[0x27], vtPalette[0x15 | (0x2a << 6)]);
    });

    test('restoring mapper state re-derives the 12-bit decode', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.ppuWrite(0x3f27, 0x15);
      nes.bus.ppuWrite(0x3fa7, 0x2a);

      nes.bus.cpuWrite(0x2010, 0x80);

      final saved = mapper.state;

      nes.bus.cpuWrite(0x2010, 0x00);

      mapper.state = saved;

      expect(nes.ppu.paletteLut[0x27], vtPalette[0x15 | (0x2a << 6)]);
    });
    test('swapping the system palette leaves the 12-bit decode alone', () {
      final (:nes, mapper: _) = buildVt02();

      nes.bus.cpuWrite(0x2010, 0x80);

      nes.bus.ppuWrite(0x3f27, 0x15);
      nes.bus.ppuWrite(0x3fa7, 0x2a);

      nes.ppu.systemPalette = expandRgbToPalette(List.filled(64, 0xff00ff));

      expect(nes.ppu.paletteLut[0x27], vtPalette[0x15 | (0x2a << 6)]);
    });

    test('reset clears COLCOMP', () {
      final (:nes, mapper: _) = buildVt02();

      nes.bus.ppuWrite(0x3f27, 0x15);
      nes.bus.ppuWrite(0x3fa7, 0x2a);

      nes.bus.cpuWrite(0x2010, 0x80);

      nes.ppu.reset();

      final low = nes.ppu.palette[0x27] & 0x3f;

      expect(nes.ppu.paletteLut[0x27], nes.ppu.systemPalette[low]);
    });

    test(r'$3F90 write is a no-op for the backdrop decode', () {
      final (:nes, mapper: _) = buildVt02();

      nes.bus.cpuWrite(0x2010, 0x80);

      nes.bus.ppuWrite(0x3f00, 0x21);
      nes.bus.ppuWrite(0x3f80, 0x0f);

      nes.bus.ppuWrite(0x3f90, 0x3f);

      expect(nes.bus.ppuRead(0x3f90), 0x3f);
      expect(nes.ppu.paletteLut[0x00], vtPalette[0x21 | (0x0f << 6)]);
      expect(nes.ppu.paletteLut[0x10], vtPalette[0x21 | (0x0f << 6)]);
    });
  });
}
