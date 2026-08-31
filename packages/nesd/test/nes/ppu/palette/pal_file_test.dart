import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/palette/pal_file.dart';

Uint8List _bytes(int count, int Function(int) generator) =>
    Uint8List.fromList(List.generate(count, generator));

void main() {
  test('parses a 1536-byte file straight through', () {
    // Entry n has r = n & 0xff, g = 0x40, b = 0x80.
    final bytes = _bytes(
      1536,
      (i) => switch (i % 3) {
        0 => (i ~/ 3) & 0xff,
        1 => 0x40,
        _ => 0x80,
      },
    );

    final palette = parsePalFile(bytes);

    expect(palette.length, equals(nesPaletteLength));
    expect(palette[0], equals(packPaletteColor(0, 0x40, 0x80)));
    expect(palette[511], equals(packPaletteColor(511 & 0xff, 0x40, 0x80)));
  });

  test('parses a 192-byte file and synthesises emphasis rows', () {
    final bytes = _bytes(
      192,
      (i) => switch (i % 3) {
        0 => 0x10,
        1 => 0x20,
        _ => 0x30,
      },
    );

    final palette = parsePalFile(bytes);

    expect(palette.length, equals(nesPaletteLength));
    expect(palette[0], equals(packPaletteColor(0x10, 0x20, 0x30)));

    final red = palette[(1 << 6) | 0];

    expect(red & 0xff, equals(0x10));
    expect((red >> 8) & 0xff, lessThan(0x20));
  });

  test('rejects a file of the wrong length', () {
    expect(() => parsePalFile(_bytes(100, (_) => 0)), throwsFormatException);
    expect(() => parsePalFile(_bytes(0, (_) => 0)), throwsFormatException);
    expect(() => parsePalFile(_bytes(1535, (_) => 0)), throwsFormatException);
  });
}
