import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';

void main() {
  test('packs colors in framebuffer word order', () {
    expect(packPaletteColor(0x12, 0x34, 0x56), equals(0xff563412));
  });

  test('expansion produces 512 entries', () {
    expect(expandRgbToPalette(defaultPaletteRgb).length, equals(512));
  });

  test('emphasis row 0 is the unmodified base palette', () {
    final palette = expandRgbToPalette(defaultPaletteRgb);

    for (var i = 0; i < 64; i++) {
      final rgb = defaultPaletteRgb[i];

      expect(
        palette[i],
        equals(
          packPaletteColor((rgb >> 16) & 0xff, (rgb >> 8) & 0xff, rgb & 0xff),
        ),
        reason: 'entry $i',
      );
    }
  });

  test('red emphasis attenuates green and blue but not red', () {
    final palette = expandRgbToPalette(const [0xffffff]);

    final base = palette[0];
    final red = palette[(1 << 6) | 0];

    expect(red & 0xff, equals(base & 0xff)); // red byte untouched
    expect((red >> 8) & 0xff, lessThan((base >> 8) & 0xff)); // green down
    expect((red >> 16) & 0xff, lessThan((base >> 16) & 0xff)); // blue down
  });

  test('blue emphasis attenuates red and green but not blue', () {
    final palette = expandRgbToPalette(const [0xffffff]);

    final base = palette[0];
    final blue = palette[(4 << 6) | 0];

    expect(blue & 0xff, lessThan(base & 0xff)); // red down
    expect((blue >> 8) & 0xff, lessThan((base >> 8) & 0xff)); // green down
    expect((blue >> 16) & 0xff, equals((base >> 16) & 0xff)); // blue untouched
  });

  test('every entry is fully opaque', () {
    final palette = expandRgbToPalette(defaultPaletteRgb);

    for (final entry in palette) {
      expect(entry & 0xff000000, equals(0xff000000));
    }
  });

  test('default palette has 64 entries', () {
    expect(defaultPaletteRgb.length, equals(64));
  });
}
