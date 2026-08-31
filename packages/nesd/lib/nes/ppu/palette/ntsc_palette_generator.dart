import 'dart:math';
import 'dart:typed_data';

import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/palette/ntsc_palette_settings.dart';

// composite signal voltages relative to sync, from NESdev
const _black = 0.518;
const _white = 1.962;

const _levels = [
  0.350, 0.518, 0.962, 1.550, // signal low
  1.094, 1.506, 1.962, 1.962, // signal high
];

bool _high(int p, int color) => (color + p + 8) % 12 < 6;

Uint32List generateNtscPalette(NtscPaletteSettings settings) {
  final palette = Uint32List(nesPaletteLength);

  for (var index = 0; index < nesPaletteLength; index++) {
    palette[index] = _generateEntry(index, settings);
  }

  return palette;
}

int _generateEntry(int index, NtscPaletteSettings settings) {
  final color = index & 0x0f;
  final emphasis = (index >> 6) & 0x07;

  var level = (index >> 4) & 0x03;

  if (color > 13) {
    level = 1;
  }

  final low = _levels[level + (color == 0 ? 4 : 0)];
  final high = _levels[level + (color < 13 ? 4 : 0)];

  var y = 0.0;
  var i = 0.0;
  var q = 0.0;

  for (var p = 0; p < 12; p++) {
    var spot = _high(p, color) ? high : low;

    if ((emphasis & 1) != 0 && _high(p, 12) ||
        (emphasis & 2) != 0 && _high(p, 4) ||
        (emphasis & 4) != 0 && _high(p, 8)) {
      spot *= emphasisAttenuation;
    }

    var v = (spot - _black) / (_white - _black);

    v = (v - 0.5) * settings.contrast + 0.5;
    v *= settings.brightness / 12.0;

    final phase = (pi / 6) * (p + settings.hue);

    y += v;
    i += v * cos(phase) * settings.saturation;
    q += v * sin(phase) * settings.saturation;
  }

  final r = y + 0.946882 * i + 0.623557 * q;
  final g = y - 0.274788 * i - 0.635691 * q;
  final b = y - 1.108545 * i + 1.709007 * q;

  return packPaletteColor(
    _toByte(r, settings.gamma),
    _toByte(g, settings.gamma),
    _toByte(b, settings.gamma),
  );
}

int _toByte(double value, double gamma) {
  final clamped = value.clamp(0.0, 1.0);

  return (pow(clamped, 2.2 / gamma) * 255.0).round().clamp(0, 255);
}
