import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/nes/ppu/ppu.dart';

import '../../test_roms/rom_robot.dart';

const _romPath = '../../roms/test/nestest/nestest.nes';

const _scanline = 50;

const _inRange = _scanline;

const _offScreen = 0xf0;

NES _console({required bool rendering}) {
  final nes = RomRobot(_romPath).nes;

  nes.bus.cpuWrite(0x2001, rendering ? 0x18 : 0x00);
  nes.ppu.oam.fillRange(0, 256, _offScreen);

  return nes;
}

void _placeSprites(PPU ppu, int count) {
  for (var sprite = 0; sprite < count; sprite++) {
    ppu.oam[sprite * 4] = _inRange;
  }
}

void _stepTo(PPU ppu, int scanline, int cycle) {
  while (ppu.scanline != scanline || ppu.cycle != cycle) {
    ppu.step();
  }
}

void main() {
  group('sprite overflow', () {
    test('is not set while rendering is off', () {
      final nes = _console(rendering: false);

      _placeSprites(nes.ppu, 9);
      _stepTo(nes.ppu, _scanline + 1, 0);

      expect(nes.ppu.PPUSTATUS_O, 0);
    });

    test('is set by a ninth sprite in range while rendering', () {
      final nes = _console(rendering: true);

      _placeSprites(nes.ppu, 9);
      _stepTo(nes.ppu, _scanline + 1, 0);

      expect(nes.ppu.PPUSTATUS_O, 1);
    });

    test('is set on the cycle the ninth in-range Y is evaluated', () {
      final nes = _console(rendering: true);

      _placeSprites(nes.ppu, 9);

      _stepTo(nes.ppu, _scanline, 130);

      expect(nes.ppu.PPUSTATUS_O, 0);

      _stepTo(nes.ppu, _scanline, 131);

      expect(nes.ppu.PPUSTATUS_O, 1);
    });

    test('scans the post-overflow bytes with the wrapping m bug', () {
      final nes = _console(rendering: true);

      _placeSprites(nes.ppu, 8);
      nes.ppu.oam[12 * 4] = _inRange;
      _stepTo(nes.ppu, _scanline + 1, 0);

      expect(nes.ppu.PPUSTATUS_O, 1);
    });

    test('does not read the byte a five-byte stride would land on', () {
      final nes = _console(rendering: true);

      _placeSprites(nes.ppu, 8);
      nes.ppu.oam[13 * 4] = _inRange;
      _stepTo(nes.ppu, _scanline + 1, 0);

      expect(nes.ppu.PPUSTATUS_O, 0);
    });
  });
}
