import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/apu_channel_samples.dart';
import 'package:nesd/nes/apu/tables.dart';

import '../../test_roms/rom_robot.dart';

const _romPath = '../../roms/test/scanline/scanline.nes';

void main() {
  test('expansion lanes are allocated on request', () {
    final samples = ApuChannelSamples(64, 3);

    expect(samples.expansion, hasLength(3));
    expect(samples.expansion.first, hasLength(64));
  });

  test('no expansion lanes by default', () {
    expect(ApuChannelSamples(64).expansion, isEmpty);
  });

  test('channelSamples is null until debug sampling is enabled', () {
    final robot = RomRobot(_romPath);

    expect(robot.nes.apu.channelSamples, isNull);
    expect(robot.nes.apu.debugSamplingEnabled, isFalse);
  });

  test('captured channel samples reproduce the mixed output exactly', () {
    final robot = RomRobot(_romPath);
    final apu = robot.nes.apu..debugSamplingEnabled = true;

    final target = robot.nes.ppu.frames + 60;
    final rounded = Float32List(1);

    var checked = 0;

    while (robot.nes.ppu.frames < target) {
      robot.nes.step();

      final channels = apu.channelSamples!;

      for (var i = 0; i < apu.sampleIndex; i++) {
        final pulseOut = pulseTable[channels.pulse1[i] + channels.pulse2[i]];
        final tndOut =
            tndTable[3 * channels.triangle[i] +
                2 * channels.noise[i] +
                channels.dmc[i]];

        rounded[0] = pulseOut + tndOut;

        expect(apu.sampleBuffer[i], rounded[0]);
      }

      checked += apu.sampleIndex;
      apu.sampleIndex = 0;
    }

    expect(checked, greaterThan(0));
  });

  test('disabling debug sampling releases the buffers', () {
    final robot = RomRobot(_romPath);
    final apu = robot.nes.apu
      ..debugSamplingEnabled = true
      ..debugSamplingEnabled = false;

    expect(apu.channelSamples, isNull);
  });
}
