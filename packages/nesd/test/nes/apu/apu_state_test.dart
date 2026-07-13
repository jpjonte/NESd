import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/apu_state.dart';

import '../../test_roms/rom_robot.dart';

void main() {
  late APUState original;

  setUp(() async {
    final robot = RomRobot('../../roms/test/nestest/nestest.nes');

    robot.nes.stop();

    await Future<void>.delayed(Duration.zero);

    final apu = robot.nes.apu;

    apu.sampleBuffer[0] = 0.25;
    apu.sampleBuffer[1] = -0.5;
    apu.sampleBuffer[2] = 0.75;
    apu.sampleIndex = 3;

    original = apu.state;
  });

  void expectStatesEqual(APUState actual, APUState expected) {
    expect(actual.cycles, expected.cycles);
    expect(actual.sampleIndex, expected.sampleIndex);
    expect(actual.sampleBuffer, expected.sampleBuffer);
    expect(actual.pulse1Samples, expected.pulse1Samples);
    expect(actual.pulse2Samples, expected.pulse2Samples);
    expect(actual.triangleSamples, expected.triangleSamples);
    expect(actual.dmcSamples, expected.dmcSamples);
    expect(actual.sampleStart, expected.sampleStart);
  }

  test('serialize writes version 1 and round-trips', () {
    final writer = Payload.write();
    original.serialize(writer);
    final bytes = binarize(writer);

    expect(bytes[0], 1, reason: 'APUState version');

    final decoded = APUState.deserialize(Payload.read(bytes));

    expectStatesEqual(decoded, original);
    expect(decoded.sampleBuffer.length, 3);
  });

  test('still reads legacy version 0 payloads', () {
    // replicate the exact v0 wire format the previous code produced,
    // delegating to the (unchanged) sub-state serializers
    final writer = Payload.write()
      ..set(uint8, 0)
      ..set(uint64, original.cycles)
      ..set(uint64, original.sampleIndex)
      ..set(list(float32), original.sampleBuffer)
      ..set(uint64, original.pulse1Samples)
      ..set(uint64, original.pulse2Samples)
      ..set(uint64, original.triangleSamples)
      ..set(uint64, original.dmcSamples)
      ..set(uint64, original.sampleStart);

    original.frameCounterState.serialize(writer);
    original.pulse1State.serialize(writer);
    original.pulse2State.serialize(writer);
    original.triangleState.serialize(writer);
    original.noiseState.serialize(writer);
    original.dmcState.serialize(writer);

    final decoded = APUState.deserialize(Payload.read(binarize(writer)));

    expectStatesEqual(decoded, original);
  });
}
