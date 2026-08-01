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
    expect(actual.expansionSamples, expected.expansionSamples);
    expect(actual.sampleStart, expected.sampleStart);
  }

  APUState withExpansionSamples(double value) => APUState(
    cycles: original.cycles,
    sampleIndex: original.sampleIndex,
    sampleBuffer: original.sampleBuffer,
    pulse1Samples: original.pulse1Samples,
    pulse2Samples: original.pulse2Samples,
    triangleSamples: original.triangleSamples,
    dmcSamples: original.dmcSamples,
    expansionSamples: value,
    sampleStart: original.sampleStart,
    frameCounterState: original.frameCounterState,
    pulse1State: original.pulse1State,
    pulse2State: original.pulse2State,
    triangleState: original.triangleState,
    noiseState: original.noiseState,
    dmcState: original.dmcState,
  );

  test('serialize writes version 2 and round-trips', () {
    final writer = Payload.write();
    original.serialize(writer);
    final bytes = binarize(writer);

    expect(bytes[0], 2, reason: 'APUState version');

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

  test('expansionSamples round-trips through version 2', () {
    final writer = Payload.write();

    withExpansionSamples(0.125).serialize(writer);

    final decoded = APUState.deserialize(Payload.read(binarize(writer)));

    expect(decoded.expansionSamples, 0.125);
  });

  test('still reads legacy version 1 payloads', () {
    // replicate the exact v1 wire format the previous code produced
    final writer = Payload.write()
      ..set(uint8, 1)
      ..set(uint64, original.cycles)
      ..set(uint64, original.sampleIndex)
      ..set(float32List(lengthType: uint32), original.sampleBuffer)
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
    expect(decoded.expansionSamples, 0);
  });
}
