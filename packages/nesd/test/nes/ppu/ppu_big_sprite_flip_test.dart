import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'four_bpp_harness.dart';

Uint8List _buildNromRom() {
  const prgSize = 0x8000;

  final rom = Uint8List(16 + prgSize + 0x2000)
    ..setAll(0, [0x4e, 0x45, 0x53, 0x1a, 2, 1, 0x00, 0x00]);

  const prgStart = 16;
  const chrStart = prgStart + prgSize;

  rom[prgStart] = 0x4c;
  rom[prgStart + 1] = 0x00;
  rom[prgStart + 2] = 0x80;
  rom[prgStart + prgSize - 4] = 0x00;
  rom[prgStart + prgSize - 3] = 0x80;

  for (var row = 0; row < 8; row++) {
    rom[chrStart + row] = 0xff;
    rom[chrStart + 16 + 8 + row] = 0xff;
  }

  return rom;
}

void main() {
  for (final (flipV, topColor, bottomColor) in [(false, 1, 2), (true, 2, 1)]) {
    test('8x16 sprite with flipV=$flipV renders colors $topColor over '
        '$bottomColor', () {
      final nes = buildNes(_buildNromRom());

      for (var i = 1; i < 4; i++) {
        nes.bus.ppuWrite(0x3f10 + i, 0x10 * i);
      }

      nes.ppu.oam.fillRange(0, 256, 0xff);
      nes.ppu.oam.setAll(0, [9, 0, flipV ? 0x80 : 0x00, 64]);

      nes.bus
        ..cpuWrite(0x2000, 0x20) // 8x16 sprites
        ..cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      for (var row = 0; row < 16; row++) {
        final color = row < 8 ? topColor : bottomColor;

        expect(
          pixelAt(nes.ppu, 68, 10 + row),
          nes.ppu.paletteLut[0x10 | color],
          reason: 'row=$row',
        );
      }
    });
  }
}
