import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';

import '../../test_roms/rom_robot.dart';
import 'four_bpp_harness.dart';

const _rom = '../../roms/test/full_palette/full_palette.nes';

Uint32List _identityPalette() {
  final palette = Uint32List(nesPaletteLength);

  for (var i = 0; i < nesPaletteLength; i++) {
    palette[i] = packPaletteColor(i & 0xff, (i >> 8) & 0xff, 0);
  }

  return palette;
}

void main() {
  test('records the palette index behind every pixel it draws', () {
    final nes = buildNes(buildEvaRom());

    nes.ppu.systemPalette = _identityPalette();

    for (var i = 0; i < 4; i++) {
      nes.bus.ppuWrite(0x3f00 + i, 0x10 + i);
    }

    nes.bus.cpuWrite(0x2001, 0x1e); // rendering on

    runFrames(nes, 2);

    nes.ppu.presentFrame();

    final palette = _identityPalette();
    final pixels = nes.ppu.frameBuffer.presentedPixels32;
    final indices = nes.ppu.frameIndices;

    expect(indices, hasLength(pixels.length));

    for (var i = 0; i < pixels.length; i++) {
      expect(
        palette[indices[i]],
        equals(pixels[i]),
        reason: 'pixel $i was drawn from a different palette entry',
      );
    }
  });

  test('records the emphasis in force when the entry was resolved', () {
    final robot = RomRobot(_rom);

    final ppu = robot.nes.ppu
      ..systemPalette = _identityPalette()
      ..palette[0] = 0x01
      ..writeRegister(0x2001, 0x00);

    expect(ppu.paletteIndexLut[0], equals(0x01));

    ppu.writeRegister(0x2001, 0x20);

    expect(ppu.paletteIndexLut[0], equals(0x41));
  });

  test('marks recorded indices stale the moment pixels are injected', () {
    final nes = buildNes(buildEvaRom());

    nes.bus.cpuWrite(0x2001, 0x1e);

    runFrames(nes, 2);
    nes.ppu.presentFrame();

    expect(nes.ppu.frameIndicesValid, isTrue);

    nes.ppu.injectFrame(Uint8List(256 * 240 * 4));

    expect(nes.ppu.frameIndicesValid, isFalse);
  });

  test('keeps a frame drawn with extended colours out of reach', () {
    final nes = buildNes(buildEvaRom());

    nes.bus.cpuWrite(0x2001, 0x1e);

    runFrames(nes, 2);
    nes.ppu.presentFrame();

    expect(nes.ppu.frameIndicesValid, isTrue);

    nes.ppu.extendedColors = true;

    runFrames(nes, nes.ppu.frames + 1);
    nes.ppu.presentFrame();

    nes.ppu.extendedColors = false;

    expect(nes.ppu.frameIndicesValid, isFalse);

    runFrames(nes, nes.ppu.frames + 1);
    nes.ppu.presentFrame();

    expect(nes.ppu.frameIndicesValid, isFalse);

    runFrames(nes, nes.ppu.frames + 1);
    nes.ppu.presentFrame();

    expect(nes.ppu.frameIndicesValid, isTrue);
  });

  test('records the greyscale mask in force when the entry was resolved', () {
    final robot = RomRobot(_rom);

    final ppu = robot.nes.ppu
      ..systemPalette = _identityPalette()
      ..palette[0] = 0x1d
      ..writeRegister(0x2001, 0x00);

    expect(ppu.paletteIndexLut[0], equals(0x1d));

    ppu.writeRegister(0x2001, 0x01); // greyscale

    expect(ppu.paletteIndexLut[0], equals(0x10));
  });

  test('marks recorded indices stale when a rewound frame is presented', () {
    final nes = buildNes(buildEvaRom());

    nes.bus.cpuWrite(0x2001, 0x1e);

    runFrames(nes, 2);
    nes.ppu.presentFrame();

    expect(nes.ppu.frameIndicesValid, isTrue);

    nes.ppu.injectFrame(Uint8List(256 * 240 * 4));
    nes.ppu.presentFrame();

    expect(nes.ppu.frameIndicesValid, isFalse);
  });

  test('marks recorded indices stale when a save state replaces the frame', () {
    final robot = RomRobot(_rom);

    runFrames(robot.nes, 2);
    robot.nes.ppu.presentFrame();

    expect(robot.nes.ppu.frameIndicesValid, isTrue);

    final state = robot.nes.ppu.state;

    runFrames(robot.nes, robot.nes.ppu.frames + 1);
    robot.nes.ppu.presentFrame();
    robot.nes.ppu.state = state;

    expect(robot.nes.ppu.frameIndicesValid, isFalse);

    runFrames(robot.nes, robot.nes.ppu.frames + 1);
    robot.nes.ppu.presentFrame();

    expect(robot.nes.ppu.frameIndicesValid, isFalse);

    runFrames(robot.nes, robot.nes.ppu.frames + 1);
    robot.nes.ppu.presentFrame();

    expect(robot.nes.ppu.frameIndicesValid, isTrue);
  });
}
