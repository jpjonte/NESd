import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/channel/noise_channel_state.dart';
import 'package:nesd/nes/apu/unit/envelope_unit_state.dart';
import 'package:nesd/nes/apu/unit/length_counter_unit_state.dart';

NoiseChannelState buildState({
  int timerPeriod = 4067,
  int timer = 4067,
  int shiftRegister = 0x7fff,
}) {
  return NoiseChannelState(
    enabled: true,
    constantVolume: false,
    volume: 15,
    timerPeriod: timerPeriod,
    timer: timer,
    shiftRegister: shiftRegister,
    mode: true,
    envelopeState: const EnvelopeUnitState(
      volume: 15,
      period: 7,
      timer: 3,
      start: true,
      loop: false,
    ),
    lengthCounterState: const LengthCounterUnitState(halt: false, value: 96),
  );
}

void expectStatesEqual(NoiseChannelState actual, NoiseChannelState expected) {
  expect(actual.enabled, expected.enabled);
  expect(actual.constantVolume, expected.constantVolume);
  expect(actual.volume, expected.volume);
  expect(actual.timerPeriod, expected.timerPeriod);
  expect(actual.timer, expected.timer);
  expect(actual.shiftRegister, expected.shiftRegister);
  expect(actual.mode, expected.mode);
  expect(actual.envelopeState.volume, expected.envelopeState.volume);
  expect(actual.envelopeState.period, expected.envelopeState.period);
  expect(actual.envelopeState.timer, expected.envelopeState.timer);
  expect(actual.envelopeState.start, expected.envelopeState.start);
  expect(actual.envelopeState.loop, expected.envelopeState.loop);
  expect(actual.lengthCounterState.halt, expected.lengthCounterState.halt);
  expect(actual.lengthCounterState.value, expected.lengthCounterState.value);
}

void main() {
  test('serialize writes version 2 and round-trips 15-bit LFSR state', () {
    final original = buildState();

    final writer = Payload.write();
    original.serialize(writer);
    final bytes = binarize(writer);

    expect(bytes[0], 2, reason: 'NoiseChannelState version');

    final decoded = NoiseChannelState.deserialize(Payload.read(bytes));

    expectStatesEqual(decoded, original);
  });

  test('still reads legacy version 1 payloads', () {
    final original = buildState(timerPeriod: 202, timer: 150, shiftRegister: 1);

    // replicate the exact v1 wire format the previous code produced
    final writer = Payload.write()
      ..set(uint8, 1)
      ..set(boolean, original.enabled)
      ..set(boolean, original.constantVolume)
      ..set(uint8, original.volume)
      ..set(uint8, original.timerPeriod)
      ..set(uint8, original.timer)
      ..set(uint8, original.shiftRegister)
      ..set(boolean, original.mode);

    original.envelopeState.serialize(writer);
    original.lengthCounterState.serialize(writer);

    final decoded = NoiseChannelState.deserialize(
      Payload.read(binarize(writer)),
    );

    expectStatesEqual(decoded, original);
  });

  test('still reads legacy version 0 payloads', () {
    final original = buildState(timerPeriod: 202, timer: 150, shiftRegister: 1);

    // v0 carried an extra, discarded period byte after volume
    final writer = Payload.write()
      ..set(uint8, 0)
      ..set(boolean, original.enabled)
      ..set(boolean, original.constantVolume)
      ..set(uint8, original.volume)
      ..set(uint8, 9) // discarded period field
      ..set(uint8, original.timerPeriod)
      ..set(uint8, original.timer)
      ..set(uint8, original.shiftRegister)
      ..set(boolean, original.mode);

    original.envelopeState.serialize(writer);
    original.lengthCounterState.serialize(writer);

    final decoded = NoiseChannelState.deserialize(
      Payload.read(binarize(writer)),
    );

    expectStatesEqual(decoded, original);
  });
}
