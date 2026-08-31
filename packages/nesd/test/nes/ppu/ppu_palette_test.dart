import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/region.dart';

import '../../test_roms/rom_robot.dart';

const _rom = '../../roms/test/full_palette/full_palette.nes';

Uint32List _identityPalette() {
  final palette = Uint32List(nesPaletteLength);

  for (var i = 0; i < nesPaletteLength; i++) {
    palette[i] = packPaletteColor(i & 0xff, (i >> 8) & 0xff, 0);
  }

  return palette;
}

void main() {
  test('rejects a palette of the wrong length', () {
    final robot = RomRobot(_rom);

    expect(
      () => robot.nes.ppu.systemPalette = Uint32List(64),
      throwsArgumentError,
    );
  });

  test('emphasis bits select the palette row', () {
    final robot = RomRobot(_rom);

    final ppu = robot.nes.ppu
      ..systemPalette = _identityPalette()
      ..palette[0] = 0x01
      ..writeRegister(0x2001, 0x00);

    expect(ppu.paletteLut[0] & 0xffff, equals(0x0001));

    ppu.writeRegister(0x2001, 0x20);

    expect(ppu.paletteLut[0] & 0xffff, equals(0x0041));

    ppu.writeRegister(0x2001, 0x80);

    expect(ppu.paletteLut[0] & 0xffff, equals(0x0101));
  });

  test('PAL swaps the red and green emphasis bits', () {
    final robot = RomRobot(_rom);

    final ppu = robot.nes.ppu
      ..systemPalette = _identityPalette()
      ..palette[0] = 0x01
      ..region = Region.pal
      ..writeRegister(0x2001, 0x20);

    expect(ppu.paletteLut[0] & 0xffff, equals(0x0081));

    ppu.writeRegister(0x2001, 0x40);

    expect(ppu.paletteLut[0] & 0xffff, equals(0x0041));
  });

  test('greyscale masks the color but keeps the emphasis row', () {
    final robot = RomRobot(_rom);

    final ppu = robot.nes.ppu
      ..systemPalette = _identityPalette()
      ..palette[0] = 0x15
      ..writeRegister(0x2001, 0x21); // greyscale + red emphasis

    expect(ppu.paletteLut[0] & 0xffff, equals(0x0050));
  });

  test('changing the region rebuilds the lookup table', () {
    final robot = RomRobot(_rom);

    final ppu = robot.nes.ppu
      ..systemPalette = _identityPalette()
      ..palette[0] = 0x01
      ..writeRegister(0x2001, 0x20);

    final ntsc = ppu.paletteLut[0];

    ppu.region = Region.pal;

    expect(ppu.paletteLut[0], isNot(equals(ntsc)));
  });
}
