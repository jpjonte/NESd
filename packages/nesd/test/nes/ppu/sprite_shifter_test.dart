import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/nes/ppu/ppu.dart';
import 'package:nesd/nes/ppu/ppu_state.dart';

import 'four_bpp_harness.dart' show buildNes;

const _line = 40;

const _spritesOnly = 0x14;

const _strip = [3, 3, 3, 3, 1, 1, 1, 1];

Uint8List _buildRom() {
  const prgSize = 0x8000;
  const chrSize = 0x2000;

  final rom = Uint8List(16 + prgSize + chrSize)
    ..setAll(0, [0x4e, 0x45, 0x53, 0x1a, 2, 1, 0, 0, 0, 0, 0, 0]);

  const chrStart = 16 + prgSize;

  for (var row = 0; row < 8; row++) {
    rom[chrStart + 16 + row] = 0xff;
    rom[chrStart + 24 + row] = 0xf0;
  }

  return rom;
}

NES _console({required int x}) {
  final nes = buildNes(_buildRom());
  final ppu = nes.ppu;

  for (var i = 1; i < 4; i++) {
    nes.bus.ppuWrite(0x3f10 + i, 0x20 + i);
  }

  ppu.oam
    ..fillRange(0, 256, 0xff)
    ..setAll(0, [_line - 1, 1, 0, x]);

  ppu.writeRegister(0x2001, _spritesOnly);

  _stepTo(ppu, 0, _line - 2, 0);

  return nes;
}

void _stepTo(PPU ppu, int frame, int scanline, int cycle) {
  while (ppu.frames != frame ||
      ppu.scanline != scanline ||
      ppu.cycle != cycle) {
    ppu.step();
  }
}

void _maskAt(PPU ppu, int scanline, int dot, int value) {
  _stepTo(ppu, ppu.frames, scanline, dot - 2);

  ppu.writeRegister(0x2001, value);
}

Map<int, int> _opaque(PPU ppu, int y) {
  final colors = {for (var v = 1; v < 4; v++) ppu.paletteLut[0x10 | v]: v};
  final pixels = ppu.frameBuffer.pixels32;

  return {for (var x = 0; x < 256; x++) x: ?colors[pixels[y * 256 + x]]};
}

Map<int, int> _drawn(int from, List<int> pixels) => {
  for (var i = 0; i < pixels.length; i++) from + i: pixels[i],
};

void main() {
  group('sprite shifters', () {
    test('draw at the X position with rendering on', () {
      final nes = _console(x: 100);

      _stepTo(nes.ppu, 0, _line + 1, 0);

      expect(_opaque(nes.ppu, _line), _drawn(100, _strip));
    });

    test('X counters keep counting while rendering is off', () {
      final nes = _console(x: 100);

      _maskAt(nes.ppu, _line, 21, 0);
      _maskAt(nes.ppu, _line, 41, _spritesOnly);
      _stepTo(nes.ppu, 0, _line + 1, 0);

      expect(_opaque(nes.ppu, _line), _drawn(100, _strip));
    });

    test('pause while rendering is off and resume where re-enabled', () {
      final nes = _console(x: 100);

      _maskAt(nes.ppu, _line, 104, 0);
      _maskAt(nes.ppu, _line, 151, _spritesOnly);
      _stepTo(nes.ppu, 0, _line + 1, 0);

      expect(_opaque(nes.ppu, _line), {
        ..._drawn(100, _strip.sublist(0, 3)),
        ..._drawn(150, _strip.sublist(3)),
      });
    });

    test('count as X = 0 when rendering is off on dot 339', () {
      final nes = _console(x: 200);

      _maskAt(nes.ppu, _line - 1, 330, 0);
      _maskAt(nes.ppu, _line, 51, _spritesOnly);
      _stepTo(nes.ppu, 0, _line + 1, 0);

      expect(_opaque(nes.ppu, _line), _drawn(50, _strip));
    });

    test('keep their count when rendering is back by dot 339', () {
      final nes = _console(x: 200);

      _maskAt(nes.ppu, _line - 1, 330, 0);
      _maskAt(nes.ppu, _line - 1, 339, _spritesOnly);
      _stepTo(nes.ppu, 0, _line + 1, 0);

      expect(_opaque(nes.ppu, _line), _drawn(200, _strip));
    });

    test('survive a save state taken while paused', () {
      final nes = _console(x: 100);

      _maskAt(nes.ppu, _line, 104, 0);
      _stepTo(nes.ppu, 0, _line, 120);

      final writer = Payload.write();
      nes.ppu.state.serialize(writer);

      final restored = _console(x: 0);

      restored.ppu.state = PPUState.deserialize(Payload.read(binarize(writer)));

      _maskAt(restored.ppu, _line, 151, _spritesOnly);
      _stepTo(restored.ppu, 0, _line + 1, 0);

      expect(
        Map.fromEntries(
          _opaque(restored.ppu, _line).entries.where((e) => e.key >= 120),
        ),
        _drawn(150, _strip.sublist(3)),
      );
    });
  });
}
