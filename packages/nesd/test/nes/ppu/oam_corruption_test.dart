import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/nes/ppu/ppu.dart';

import '../../test_roms/rom_robot.dart';

const _romPath = '../../roms/test/nestest/nestest.nes';

const _scanline = 50;

const _seededRow = 5;

NES _console({required bool oamCorruption}) {
  final nes = RomRobot(_romPath).nes;

  nes.ppu.oamCorruption = oamCorruption;
  nes.bus.cpuWrite(0x2001, 0x18);

  for (var i = 0; i < 256; i++) {
    nes.ppu.oam[i] = i;
  }

  return nes;
}

void _stepTo(PPU ppu, int scanline, int cycle) {
  while (ppu.scanline != scanline || ppu.cycle != cycle) {
    ppu.step();
  }
}

List<int> _row(PPU ppu, int row) => ppu.oam.sublist(row * 8, row * 8 + 8);

void _switchOffMidClear(NES nes) {
  _stepTo(nes.ppu, _scanline, 8);

  nes.bus.cpuWrite(0x2001, 0x00);

  _stepTo(nes.ppu, _scanline, 20);
}

void main() {
  group('OAM corruption', () {
    test('waits for rendering to come back on', () {
      final nes = _console(oamCorruption: true);

      _switchOffMidClear(nes);
      _stepTo(nes.ppu, _scanline + 2, 0);

      expect(_row(nes.ppu, _seededRow), isNot(_row(nes.ppu, 0)));
    });

    test('copies row 0 over the seeded row on the next rendered dot', () {
      final nes = _console(oamCorruption: true);

      _switchOffMidClear(nes);

      nes.bus.cpuWrite(0x2001, 0x18);

      _stepTo(nes.ppu, _scanline, 40);

      expect(_row(nes.ppu, _seededRow), _row(nes.ppu, 0));
      expect(_row(nes.ppu, _seededRow + 1), isNot(_row(nes.ppu, 0)));
    });

    test('does not happen outside the rendered lines', () {
      final nes = _console(oamCorruption: true);

      _stepTo(nes.ppu, 245, 8);

      nes.bus.cpuWrite(0x2001, 0x00);

      _stepTo(nes.ppu, 245, 20);

      nes.bus.cpuWrite(0x2001, 0x18);

      _stepTo(nes.ppu, 10, 0);

      for (var row = 1; row < 32; row++) {
        expect(_row(nes.ppu, row), isNot(_row(nes.ppu, 0)));
      }
    });

    test('leaves OAM alone when switched off', () {
      final nes = _console(oamCorruption: false);

      _switchOffMidClear(nes);

      nes.bus.cpuWrite(0x2001, 0x18);

      _stepTo(nes.ppu, _scanline, 40);

      expect(_row(nes.ppu, _seededRow), isNot(_row(nes.ppu, 0)));
    });

    test('drops a pending corruption when it is switched off', () {
      final nes = _console(oamCorruption: true);

      _switchOffMidClear(nes);

      nes.ppu.oamCorruption = false;
      nes.bus.cpuWrite(0x2001, 0x18);

      _stepTo(nes.ppu, _scanline, 40);

      expect(_row(nes.ppu, _seededRow), isNot(_row(nes.ppu, 0)));
    });
  });
}
