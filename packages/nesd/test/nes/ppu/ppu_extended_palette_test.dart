import 'package:flutter_test/flutter_test.dart';

import '../cartridge/mapper/vt/vt02_harness.dart';

void main() {
  group('VT extended palette', () {
    test(r'$3F24 is a real entry, distinct from $3F04', () {
      final (:nes, mapper: _) = buildVt02();

      nes.bus.ppuWrite(0x3f04, 0x11);
      nes.bus.ppuWrite(0x3f24, 0x22);

      expect(nes.bus.ppuRead(0x3f04), 0x11);
      expect(nes.bus.ppuRead(0x3f24), 0x22);
    });

    test(r'only $3F10/14/18/1C mirror the backdrop column', () {
      final (:nes, mapper: _) = buildVt02();

      nes.bus.ppuWrite(0x3f10, 0x15);
      nes.bus.ppuWrite(0x3f30, 0x25);

      expect(nes.bus.ppuRead(0x3f00), 0x15);
      expect(nes.bus.ppuRead(0x3f30), 0x25);
      expect(nes.bus.ppuRead(0x3f00), 0x15); // $3F30 did not alias
    });

    test('high-half writes leave the low half and the LUT alone', () {
      final (:nes, mapper: _) = buildVt02();

      nes.bus.ppuWrite(0x3f11, 0x2a);

      final before = nes.ppu.paletteLut[0x11];

      nes.bus.ppuWrite(0x3f91, 0x3f);

      expect(nes.bus.ppuRead(0x3f11), 0x2a);
      expect(nes.bus.ppuRead(0x3f91), 0x3f);
      expect(nes.ppu.paletteLut[0x11], before);
    });

    test('LUT entries above the stock space update on write', () {
      final (:nes, mapper: _) = buildVt02();

      nes.bus.ppuWrite(0x3f27, 0x16);

      expect(nes.ppu.paletteLut[0x27], nes.ppu.systemPalette[0x16]);
    });

    test('writing the backdrop refreshes its sprite-half mirror', () {
      final (:nes, mapper: _) = buildVt02();

      nes.bus.ppuWrite(0x3f00, 0x21);

      expect(nes.ppu.paletteLut[0x10], nes.ppu.paletteLut[0x00]);
    });

    test(r'$3F90 does not mirror $3F80', () {
      final (:nes, mapper: _) = buildVt02();

      nes.bus.ppuWrite(0x3f80, 0x11);
      nes.bus.ppuWrite(0x3f90, 0x2c);

      expect(nes.bus.ppuRead(0x3f90), 0x2c);
      expect(nes.bus.ppuRead(0x3f80), 0x11);
    });

    test(r'$3FFF is a real entry, distinct from $3F7F', () {
      final (:nes, mapper: _) = buildVt02();

      nes.bus.ppuWrite(0x3f7f, 0x11);
      nes.bus.ppuWrite(0x3fff, 0x22);

      expect(nes.bus.ppuRead(0x3f7f), 0x11);
      expect(nes.bus.ppuRead(0x3fff), 0x22);
    });
  });
}
