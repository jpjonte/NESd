import 'dart:typed_data';

import 'package:nesd/nes/ppu/palette/nes_palette.dart';

const _baseOnlyLength = 64 * 3;
const _fullLength = nesPaletteLength * 3;

Uint32List parsePalFile(Uint8List bytes) {
  if (bytes.length == _baseOnlyLength) {
    return expandRgbToPalette(_readRgb(bytes, 64));
  }

  if (bytes.length != _fullLength) {
    throw FormatException(
      'expected a $_baseOnlyLength or $_fullLength byte .pal file, '
      'got ${bytes.length} bytes',
    );
  }

  final palette = Uint32List(nesPaletteLength);

  for (var i = 0; i < nesPaletteLength; i++) {
    final offset = i * 3;

    palette[i] = packPaletteColor(
      bytes[offset],
      bytes[offset + 1],
      bytes[offset + 2],
    );
  }

  return palette;
}

List<int> _readRgb(Uint8List bytes, int count) => [
  for (var i = 0; i < count; i++)
    (bytes[i * 3] << 16) | (bytes[i * 3 + 1] << 8) | bytes[i * 3 + 2],
];
