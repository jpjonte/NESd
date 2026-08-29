import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/expansion/mmc5_audio.dart';

import '../../test_roms/rom_robot.dart';

Future<RomRobot> stoppedRobot(String path) async {
  final robot = RomRobot(path);

  robot.nes.stop();

  await Future<void>.delayed(Duration.zero);

  return robot;
}

void main() {
  group('APU.swapDutyCycles', () {
    late RomRobot robot;

    setUp(() async {
      robot = await stoppedRobot('../../roms/test/nestest/nestest.nes');
    });

    test('is off by default', () {
      final apu = robot.nes.apu;

      expect(apu.swapDutyCycles, isFalse);
      expect(apu.pulse1.swapDutyCycles, isFalse);
      expect(apu.pulse2.swapDutyCycles, isFalse);
    });

    test('reaches both pulse channels', () {
      final apu = robot.nes.apu..swapDutyCycles = true;

      expect(apu.swapDutyCycles, isTrue);
      expect(apu.pulse1.swapDutyCycles, isTrue);
      expect(apu.pulse2.swapDutyCycles, isTrue);
    });

    test('turning it back off reaches both pulse channels', () {
      final apu = robot.nes.apu
        ..swapDutyCycles = true
        ..swapDutyCycles = false;

      expect(apu.pulse1.swapDutyCycles, isFalse);
      expect(apu.pulse2.swapDutyCycles, isFalse);
    });

    test('survives a reset', () {
      final apu = robot.nes.apu
        ..swapDutyCycles = true
        ..reset();

      expect(apu.pulse1.swapDutyCycles, isTrue);
      expect(apu.pulse2.swapDutyCycles, isTrue);
    });

    test('survives loading a state captured before it was enabled', () {
      final apu = robot.nes.apu;

      final state = apu.state;

      apu
        ..swapDutyCycles = true
        ..state = state;

      expect(apu.pulse1.swapDutyCycles, isTrue);
      expect(apu.pulse2.swapDutyCycles, isTrue);
    });

    test('leaves MMC5 pulses alone', () async {
      final mmc5 = await stoppedRobot(
        '../../roms/test/mmc5test_v2/mmc5test.nes',
      );

      final expansion = mmc5.nes.apu.expansionAudio! as Mmc5Audio;

      mmc5.nes.apu.swapDutyCycles = true;

      expect(expansion.pulse1.swapDutyCycles, isFalse);
      expect(expansion.pulse2.swapDutyCycles, isFalse);
    });
  });
}
