import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../../test_roms/rom_robot.dart';

const _romPath = '../../roms/test/scanline/scanline.nes';

void main() {
  test('APU sample stream is unchanged', () {
    final robot = RomRobot(_romPath);

    var hash = 0xcbf29ce484222325;
    final target = robot.nes.ppu.frames + 120;
    final sampleBits = ByteData(4);

    while (robot.nes.ppu.frames < target) {
      robot.nes.step();

      final apu = robot.nes.apu;

      for (var i = 0; i < apu.sampleIndex; i++) {
        sampleBits.setFloat32(0, apu.sampleBuffer[i], Endian.little);

        hash = (hash ^ sampleBits.getUint32(0, Endian.little)) * 0x100000001b3;
      }

      apu.sampleIndex = 0;
    }

    expect(hash, 8769391392806128493);
  });
}
