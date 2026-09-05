import 'dart:typed_data';

/// 64 colors * 8 emphasis states = 512 entries
/// indexed by `(emphasis << 6) | color`, emphasis = bgr
const nesPaletteLength = 512;

const emphasisAttenuation = 0.746;

enum NesPaletteId { defaultPalette, warm, cool, flat, generated, user }

extension NesPaletteIdName on NesPaletteId {
  String get displayName => switch (this) {
    NesPaletteId.defaultPalette => 'Default',
    NesPaletteId.warm => 'Warm',
    NesPaletteId.cool => 'Cool',
    NesPaletteId.flat => 'Flat',
    NesPaletteId.generated => 'Generated (NTSC)',
    NesPaletteId.user => 'User',
  };
}

const defaultPaletteRgb = [
  0x626262,
  0x001fb2,
  0x2404c8,
  0x5200b2,
  0x730076,
  0x800024,
  0x730b00,
  0x522800,
  0x244400,
  0x005700,
  0x005c00,
  0x005324,
  0x003c76,
  0x000000,
  0x000000,
  0x000000,
  0xababab,
  0x0d57ff,
  0x4b30ff,
  0x8a13ff,
  0xbc08d6,
  0xd21269,
  0xc72e00,
  0x9d5400,
  0x607b00,
  0x209800,
  0x00a300,
  0x009942,
  0x007db4,
  0x000000,
  0x000000,
  0x000000,
  0xffffff,
  0x53aeff,
  0x9085ff,
  0xd365ff,
  0xff57ff,
  0xff5dcf,
  0xff7757,
  0xfa9e00,
  0xbdc700,
  0x7ae700,
  0x43f611,
  0x26ef7e,
  0x2cd5f6,
  0x4e4e4e,
  0x000000,
  0x000000,
  0xffffff,
  0xb6e1ff,
  0xced1ff,
  0xe9c3ff,
  0xffbcff,
  0xffbdf4,
  0xffc6c3,
  0xffd59a,
  0xe9e681,
  0xcef481,
  0xb6fb9a,
  0xa9fac3,
  0xa9f0f4,
  0xb8b8b8,
  0x000000,
  0x000000,
];

int packPaletteColor(int r, int g, int b) =>
    0xff000000 | (b << 16) | (g << 8) | r;

Uint32List expandRgbToPalette(List<int> rgb) {
  final palette = Uint32List(nesPaletteLength);

  for (var emphasis = 0; emphasis < 8; emphasis++) {
    final dimRed = (emphasis & 0x06) != 0;
    final dimGreen = (emphasis & 0x05) != 0;
    final dimBlue = (emphasis & 0x03) != 0;

    for (var color = 0; color < rgb.length; color++) {
      final value = rgb[color];

      final r = _attenuate((value >> 16) & 0xff, dimRed);
      final g = _attenuate((value >> 8) & 0xff, dimGreen);
      final b = _attenuate(value & 0xff, dimBlue);

      palette[(emphasis << 6) | color] = packPaletteColor(r, g, b);
    }
  }

  return palette;
}

final defaultPalette = expandRgbToPalette(defaultPaletteRgb);

int _attenuate(int channel, bool dim) =>
    dim ? (channel * emphasisAttenuation).round() : channel;
