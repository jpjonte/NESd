import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/palette/ntsc_palette_generator.dart';
import 'package:nesd/nes/ppu/palette/ntsc_palette_settings.dart';

int _r(int word) => word & 0xff;
int _g(int word) => (word >> 8) & 0xff;
int _b(int word) => (word >> 16) & 0xff;

double _luma(int word) =>
    0.299 * _r(word) + 0.587 * _g(word) + 0.114 * _b(word);

void main() {
  const defaults = NtscPaletteSettings();

  test('produces a full palette', () {
    expect(generateNtscPalette(defaults).length, equals(nesPaletteLength));
  });

  test('is deterministic', () {
    expect(
      generateNtscPalette(defaults),
      equals(generateNtscPalette(defaults)),
    );
  });

  test('every entry is fully opaque', () {
    for (final entry in generateNtscPalette(defaults)) {
      expect(entry & 0xff000000, equals(0xff000000));
    }
  });

  test('the grey column is near-neutral', () {
    final palette = generateNtscPalette(defaults);

    for (final color in [0x00, 0x10, 0x20, 0x30]) {
      final word = palette[color];

      expect((_r(word) - _g(word)).abs(), lessThan(12), reason: '$color r/g');
      expect((_g(word) - _b(word)).abs(), lessThan(12), reason: '$color g/b');
    }
  });

  test('colors 0x0d..0x0f are near black', () {
    final palette = generateNtscPalette(defaults);

    for (final color in [0x0d, 0x0e, 0x0f]) {
      expect(_luma(palette[color]), lessThan(40), reason: '$color');
    }
  });

  test('raising brightness raises mean luminance', () {
    double mean(NtscPaletteSettings s) {
      final palette = generateNtscPalette(s);

      var total = 0.0;

      for (var i = 0; i < 64; i++) {
        total += _luma(palette[i]);
      }

      return total / 64;
    }

    final dim = mean(defaults.copyWith(brightness: 0.8));
    final normal = mean(defaults);
    final bright = mean(defaults.copyWith(brightness: 1.2));

    expect(dim, lessThan(normal));
    expect(normal, lessThan(bright));
  });

  test('zero saturation yields greys throughout', () {
    final palette = generateNtscPalette(defaults.copyWith(saturation: 0));

    for (var i = 0; i < 64; i++) {
      final word = palette[i];

      expect((_r(word) - _b(word)).abs(), lessThan(12), reason: 'entry $i');
    }
  });

  test('every emphasis row is no brighter than the base row', () {
    final palette = generateNtscPalette(defaults);

    double rowMean(int emphasis) {
      var total = 0.0;

      for (var color = 0; color < 64; color++) {
        total += _luma(palette[(emphasis << 6) | color]);
      }

      return total / 64;
    }

    final base = rowMean(0);

    for (var emphasis = 1; emphasis < 8; emphasis++) {
      expect(rowMean(emphasis), lessThan(base), reason: 'row $emphasis');
    }
  });

  test('primary hues land on the expected channels', () {
    final palette = generateNtscPalette(defaults);

    final blue = palette[0x21];
    final red = palette[0x26];
    final green = palette[0x2a];

    expect(_b(blue), greaterThan(_r(blue)));
    expect(_b(blue), greaterThan(_g(blue)));

    expect(_r(red), greaterThan(_g(red)));
    expect(_r(red), greaterThan(_b(red)));

    expect(_g(green), greaterThan(_r(green)));
    expect(_g(green), greaterThan(_b(green)));
  });

  test('hue rotation moves chromatic colors but leaves greys neutral', () {
    final base = generateNtscPalette(defaults);
    final rotated = generateNtscPalette(defaults.copyWith(hue: 3));

    expect(rotated[0x21], isNot(equals(base[0x21])));

    for (final color in [0x00, 0x10, 0x20, 0x30]) {
      final word = rotated[color];

      expect((_r(word) - _g(word)).abs(), lessThan(12), reason: '$color r/g');
      expect((_g(word) - _b(word)).abs(), lessThan(12), reason: '$color g/b');
    }
  });

  test('raising contrast increases luminance spread', () {
    double spread(NtscPaletteSettings s) {
      final palette = generateNtscPalette(s);

      var lowest = double.infinity;
      var highest = -double.infinity;

      for (var i = 0; i < 64; i++) {
        final luma = _luma(palette[i]);

        lowest = luma < lowest ? luma : lowest;
        highest = luma > highest ? luma : highest;
      }

      return highest - lowest;
    }

    final low = spread(defaults.copyWith(contrast: 0.3));
    final mid = spread(defaults.copyWith(contrast: 0.5));
    final high = spread(defaults.copyWith(contrast: 0.7));

    expect(low, lessThan(mid));
    expect(mid, lessThan(high));
  });

  test('raising gamma raises mean luminance', () {
    double mean(NtscPaletteSettings s) {
      final palette = generateNtscPalette(s);

      var total = 0.0;

      for (var i = 0; i < 64; i++) {
        total += _luma(palette[i]);
      }

      return total / 64;
    }

    final low = mean(defaults.copyWith(gamma: 1.4));
    final normal = mean(defaults);
    final high = mean(defaults.copyWith(gamma: 2.2));

    expect(low, lessThan(normal));
    expect(normal, lessThan(high));
  });
}
