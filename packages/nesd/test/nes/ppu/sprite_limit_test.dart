import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/nes/ppu/ppu.dart';

import 'four_bpp_harness.dart' show buildNes;

const _line = 40;

const _spritesOnly = 0x14;

/// Tile 1: [1, 1, 1, 1, 1, 1, 1, 1]
/// Tile 2: [3, 3, 0, 0, 0, 0, 0, 0]
/// Tile 3: [1, 1, 1, 1, 0, 0, 0, 0]
/// Tile 4: [2, 2, 2, 2, 2, 2, 2, 2]
Uint8List _buildRom() {
  const prgSize = 0x8000;
  const chrSize = 0x2000;

  final rom = Uint8List(16 + prgSize + chrSize)
    ..setAll(0, [0x4e, 0x45, 0x53, 0x1a, 2, 1, 0, 0, 0, 0, 0, 0]);

  const chrStart = 16 + prgSize;

  for (var row = 0; row < 8; row++) {
    rom[chrStart + 0x10 + row] = 0xff;
    rom[chrStart + 0x20 + row] = 0xc0;
    rom[chrStart + 0x28 + row] = 0xc0;
    rom[chrStart + 0x30 + row] = 0xf0;
    rom[chrStart + 0x48 + row] = 0xff;
  }

  return rom;
}

NES _console({
  required bool removeSpriteLimit,
  required List<(int, int)> sprites,
}) {
  final nes = buildNes(_buildRom());
  final ppu = nes.ppu..removeSpriteLimit = removeSpriteLimit;

  for (var i = 1; i < 4; i++) {
    nes.bus.ppuWrite(0x3f10 + i, 0x20 + i);
  }

  ppu.oam.fillRange(0, 256, 0xff);

  for (final (index, (tile, x)) in sprites.indexed) {
    ppu.oam.setAll(index * 4, [_line - 1, tile, 0, x]);
  }

  ppu.writeRegister(0x2001, _spritesOnly);

  return nes;
}

List<(int, int)> _row(int count, {int spacing = 8}) => [
  for (var i = 0; i < count; i++) (1, i * spacing),
];

void _stepTo(PPU ppu, int scanline, int cycle) {
  while (ppu.frames != 0 || ppu.scanline != scanline || ppu.cycle != cycle) {
    ppu.step();
  }
}

Map<int, int> _opaque(PPU ppu, int y) {
  final colors = {for (var v = 1; v < 4; v++) ppu.paletteLut[0x10 | v]: v};
  final pixels = ppu.frameBuffer.pixels32;

  return {for (var x = 0; x < 256; x++) x: ?colors[pixels[y * 256 + x]]};
}

Map<int, int> _drawn(int from, List<int> pixels) => {
  for (var i = 0; i < pixels.length; i++) from + i: pixels[i],
};

Uint8List _serializedState(PPU ppu) {
  final writer = Payload.write();

  ppu.state.serialize(writer);

  return binarize(writer);
}

void main() {
  group('sprite limit', () {
    test('drops the sprites after the eighth by default', () {
      final nes = _console(removeSpriteLimit: false, sprites: _row(10));

      _stepTo(nes.ppu, _line + 1, 0);

      expect(_opaque(nes.ppu, _line), _drawn(0, List.filled(64, 1)));
    });

    test('draws every sprite on the line when removed', () {
      final nes = _console(removeSpriteLimit: true, sprites: _row(10));

      _stepTo(nes.ppu, _line + 1, 0);

      expect(_opaque(nes.ppu, _line), _drawn(0, List.filled(80, 1)));
    });

    test('draws all 64 sprites on one line when removed', () {
      final nes = _console(
        removeSpriteLimit: true,
        sprites: _row(64, spacing: 4),
      );

      _stepTo(nes.ppu, _line + 1, 0);

      expect(_opaque(nes.ppu, _line), _drawn(0, List.filled(256, 1)));
    });

    test('ranks the extra sprites below the eighth in OAM order', () {
      final nes = _console(
        removeSpriteLimit: true,
        sprites: [..._row(7, spacing: 0), (2, 100), (3, 100), (4, 100)],
      );

      _stepTo(nes.ppu, _line + 1, 0);

      expect(_opaque(nes.ppu, _line), {
        ..._drawn(0, List.filled(8, 1)),
        ..._drawn(100, [3, 3, 1, 1, 2, 2, 2, 2]),
      });
    });

    test('still sets the overflow flag when removed', () {
      final nes = _console(removeSpriteLimit: true, sprites: _row(9));

      _stepTo(nes.ppu, _line, 0);

      expect(nes.ppu.PPUSTATUS_O, 1);
    });

    test('applies from the next sprite fetch when turned on mid-frame', () {
      final nes = _console(removeSpriteLimit: false, sprites: _row(10));

      _stepTo(nes.ppu, _line + 1, 0);

      nes.ppu.removeSpriteLimit = true;

      _stepTo(nes.ppu, _line + 3, 0);

      expect(_opaque(nes.ppu, _line + 1), _drawn(0, List.filled(64, 1)));
      expect(_opaque(nes.ppu, _line + 2), _drawn(0, List.filled(80, 1)));
    });

    test(
      'drops the extra sprites from the next sprite fetch when turned off',
      () {
        final nes = _console(removeSpriteLimit: true, sprites: _row(10));

        _stepTo(nes.ppu, _line + 1, 0);

        nes.ppu.removeSpriteLimit = false;

        _stepTo(nes.ppu, _line + 3, 0);

        expect(_opaque(nes.ppu, _line + 1), _drawn(0, List.filled(80, 1)));
        expect(_opaque(nes.ppu, _line + 2), _drawn(0, List.filled(64, 1)));
      },
    );

    test('leaves save states untouched', () {
      final limited = _console(removeSpriteLimit: false, sprites: _row(10));
      final unlimited = _console(removeSpriteLimit: true, sprites: _row(10));

      _stepTo(limited.ppu, _line - 1, 330);
      _stepTo(unlimited.ppu, _line - 1, 330);

      expect(_serializedState(unlimited.ppu), _serializedState(limited.ppu));
    });
  });
}
