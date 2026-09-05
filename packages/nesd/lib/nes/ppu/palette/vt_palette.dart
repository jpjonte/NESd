import 'dart:math';
import 'dart:typed_data';

import 'package:nesd/nes/ppu/palette/nes_palette.dart';

final Uint32List vtPalette = _generateVtPalette();

const _altHues = [13, 7, 8, 9, 10, 11, 12, 1, 2, 3, 4, 5, 6, 0, 14, 15];

const _altPhaseOffsets = [
  -5.0, -5.0, -5.0, -5.0, -5.0, -5.0, -5.0, -5.0, //
  -5.0, -5.0, -5.0, -5.0, 0.0, -5.0, -5.0, -5.0,
];

Uint32List _generateVtPalette() {
  final palette = Uint32List(0x1000);

  for (var value = 0; value < 0x1000; value++) {
    palette[value] = _decode(value);
  }

  return palette;
}

/// NewRisingSun 12-bit HSV formula as implemented in MAME's
/// `init_vt03_palette_tables`. Its constants were tuned to match the EmuVT
/// reference palette. See https://www.nesdev.org/wiki/VT03+_Enhanced_Palette
int _decode(int value) {
  var hue = value & 0xf;
  var luma = (value >> 4) & 0xf;
  var saturation = (value >> 8) & 0xf;
  var phaseOffset = -11.0;

  final inverted =
      luma < ((saturation + 1) >> 1) || luma > 15 - (saturation >> 1);

  if (inverted) {
    phaseOffset += _altPhaseOffsets[hue];
    hue = _altHues[hue];
    saturation = 16 - saturation;
    luma = (luma - 8) & 0xf;
  }

  final chroma = saturation / 18.975;
  final phase = ((hue - 2) * 30.0 + phaseOffset) * pi / 180.0;

  var y = (luma - 4) / 9.625;
  var c = chroma;

  if (hue == 0 || hue > 12) {
    c = 0;
  }

  if (hue == 0) {
    y += chroma;
  }

  if (hue == 13) {
    y -= chroma;
  }

  if (hue >= 14) {
    y = 0;
  }

  final v = sin(phase) * c * 1.05;
  final u = cos(phase) * c * 1.05;

  final r = y + 1.14 * v;
  final g = y - 0.5807 * v - 0.394 * u;
  final b = y + 2.029 * u;

  return packPaletteColor(_toByte(r), _toByte(g), _toByte(b));
}

int _toByte(double channel) => (channel.clamp(0.0, 1.0) * 255.0).toInt();
