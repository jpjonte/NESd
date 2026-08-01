import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/tables.dart';

import '../../../test_roms/rom_robot.dart';
import '../../cartridge/mapper/mmc5_harness.dart';

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

    // The first sample after a reset is averaged over one cycle too few
    // (issue #245), so assert on the second, which uses a correct window.
    expect(apu.sampleIndex, greaterThan(1));
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
}
