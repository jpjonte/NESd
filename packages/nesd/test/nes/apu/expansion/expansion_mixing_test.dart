import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/tables.dart';

import '../../../test_roms/rom_robot.dart';
import '../../cartridge/mapper/mmc5_harness.dart';
import '../../cartridge/mapper/namco163_harness.dart';

void main() {
  test('a non-MMC5 cartridge contributes nothing', () {
    final robot = RomRobot('../../roms/test/nestest/nestest.nes');

    robot.nes.stop();

    expect(robot.nes.bus.cartridge.mapper.expansionAudio, isNull);
  });

  test('MMC5 audio reaches the mixed sample buffer', () {
    final mapper = buildMmc5();
    final apu = mapper.bus.apu..reset();

    mapper.cpuWrite(0x5011, 0xff);

    // Gather two samples
    for (var i = 0; i < 256; i++) {
      apu.step();
      mapper.step();
    }

    expect(apu.sampleIndex, greaterThan(1));
    expect(apu.sampleBuffer[0], closeTo(tndTable[127], 1e-6));
    expect(apu.sampleBuffer[1], closeTo(tndTable[127], 1e-6));
  });

  test('a silent MMC5 leaves the mix untouched', () {
    final mapper = buildMmc5();
    final apu = mapper.bus.apu..reset();

    for (var i = 0; i < 256; i++) {
      apu.step();
      mapper.step();
    }

    expect(apu.sampleBuffer[0], 0);
  });

  test('Namco 163 audio reaches the mixed sample buffer', () {
    final mapper = buildNamco163();
    final apu = mapper.bus.apu..reset();

    mapper.audio.ram[0x7f] = 0x0f;
    mapper.audio.ram[0x7c] = 0xfc;
    mapper.audio.ram[0x78] = 0x00;
    mapper.audio.ram[0x7a] = 0x01;

    for (var i = 0; i < 256; i++) {
      apu.step();
      mapper.step();
    }

    expect(apu.sampleIndex, greaterThan(1));
    expect(apu.sampleBuffer[1], lessThan(0));
  });
}
