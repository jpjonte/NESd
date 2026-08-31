import 'package:flutter_test/flutter_test.dart';

import '../../test_roms/rom_robot.dart';

const _romPath = '../../roms/test/nestest/nestest.nes';

void main() {
  test(r'OAMADDR wraps to 0 after 256 writes to $2004', () {
    final robot = RomRobot(_romPath);
    final nes = robot.nes;

    while (nes.ppu.scanline < 241) {
      nes.step();

      nes.apu.sampleIndex = 0;
    }

    nes.bus.cpuWrite(0x2003, 0x00);

    for (var i = 0; i < 257; i++) {
      nes.bus.cpuWrite(0x2004, i & 0xff);
    }

    expect(nes.ppu.OAMADDR, equals(1));
    expect(nes.ppu.oam[0], equals(256 & 0xff));
    expect(nes.ppu.oam[1], equals(1));
  });
}
