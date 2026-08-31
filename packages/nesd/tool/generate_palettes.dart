import 'dart:io';
import 'dart:typed_data';

import 'package:nesd/nes/ppu/palette/ntsc_palette_generator.dart';
import 'package:nesd/nes/ppu/palette/ntsc_palette_settings.dart';

const _presets = {
  'warm': NtscPaletteSettings(hue: -0.3, saturation: 1.15, gamma: 1.9),
  'cool': NtscPaletteSettings(hue: 0.3, saturation: 1.05, gamma: 1.7),
  'flat': NtscPaletteSettings(saturation: 0.75, contrast: 0.9, gamma: 2.0),
};

void main() {
  for (final entry in _presets.entries) {
    final palette = generateNtscPalette(entry.value);

    final bytes = Uint8List(palette.length * 3);

    for (var i = 0; i < palette.length; i++) {
      final word = palette[i];

      bytes[i * 3] = word & 0xff;
      bytes[i * 3 + 1] = (word >> 8) & 0xff;
      bytes[i * 3 + 2] = (word >> 16) & 0xff;
    }

    File('assets/palettes/${entry.key}.pal').writeAsBytesSync(bytes);
  }
}
