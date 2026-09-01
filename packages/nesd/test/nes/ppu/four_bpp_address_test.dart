import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/four_bpp_address.dart';

void main() {
  group('planar', () {
    test('tile bytes move to a 32-byte stride', () {
      // tile 1, fine Y 3, plane 0
      expect(fourBppPlanarAddress(0x013, 0), 0x023);
      // plane 1 (+8)
      expect(fourBppPlanarAddress(0x01b, 0), 0x02b);
      // planes 2/3 sit at +16/+24
      expect(fourBppPlanarAddress(0x013, 1), 0x033);
      expect(fourBppPlanarAddress(0x01b, 1), 0x03b);
    });

    test('pattern table bit tops the doubled space', () {
      expect(fourBppPlanarAddress(0x1000, 0), 0x2000);
      expect(fourBppPlanarAddress(0x1fff, 1), 0x3fff);
    });

    test('tile slot bits shift with the tile', () {
      expect(fourBppPlanarAddress(0x400, 0), 0x800);
    });
  });

  group('wide', () {
    test('doubles the byte address with the plane pair in bit 0', () {
      expect(fourBppWideAddress(0x000, 0), 0x000);
      expect(fourBppWideAddress(0x000, 1), 0x001);
      expect(fourBppWideAddress(0x008, 0), 0x010);
      expect(fourBppWideAddress(0x00b, 1), 0x017);
      expect(fourBppWideAddress(0x1fff, 1), 0x3fff);
    });
  });
}
