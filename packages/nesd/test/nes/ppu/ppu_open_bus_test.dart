import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/nes.dart';

import '../../test_roms/rom_robot.dart';

const _romPath = '../../roms/test/nestest/nestest.nes';

NES _bootedNes() {
  final robot = RomRobot(_romPath);

  while (robot.nes.ppu.scanline != 245) {
    robot.nes.step();

    robot.nes.apu.sampleIndex = 0;
  }

  return robot.nes;
}

void main() {
  test('write-only registers read back the decay value', () {
    final nes = _bootedNes();

    nes.bus.cpuWrite(0x2000, 0xa5);

    expect(nes.bus.cpuRead(0x2000), equals(0xa5));
    expect(nes.bus.cpuRead(0x2001), equals(0xa5));
  });

  test(r'reading $2002 leaves the low five decay bits alone', () {
    final nes = _bootedNes();

    nes.bus.cpuWrite(0x2002, 0xff);

    expect(nes.bus.cpuRead(0x2002) & 0x1f, equals(0x1f));
  });

  test('reading a sprite attribute byte refreshes every decay bit', () {
    final nes = _bootedNes();

    nes.ppu.oam[2] = 0xff;

    nes.bus
      ..cpuWrite(0x2003, 0x02)
      ..cpuWrite(0x2002, 0xff);

    expect(nes.bus.cpuRead(0x2004) & 0x1c, equals(0));

    expect(nes.bus.cpuRead(0x2000) & 0x1c, equals(0));
  });
}
