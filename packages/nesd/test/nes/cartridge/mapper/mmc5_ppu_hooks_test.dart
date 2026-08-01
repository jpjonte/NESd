import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/mmc5.dart';

import '../../../test_roms/rom_robot.dart';

const _romPath = '../../roms/test/mmc5test_v2/mmc5test.nes';

void main() {
  test('the MMC5 scanline counter advances while the PPU renders', () {
    final robot = RomRobot(_romPath)..runFrames(60);
    final mapper = robot.nes.bus.cartridge.mapper as MMC5;

    var maxScanline = 0;

    // Sample inside frames: the NMI vector read resets the counter at VBlank,
    // so sampling on frame boundaries always reads zero.
    final target = robot.nes.ppu.frames + 4;

    while (robot.nes.ppu.frames < target) {
      for (var i = 0; i < 200; i++) {
        robot.nes.step();
      }

      robot.nes.apu.sampleIndex = 0;

      final scanline = mapper.state.scanline;

      if (scanline > maxScanline) {
        maxScanline = scanline;
      }
    }

    expect(
      maxScanline,
      greaterThan(0),
      reason: 'MMC5 never observed a scanline: its PPU hooks are dead',
    );
  });
}
