import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/channel/triangle_channel_state.dart';
import 'package:nesd/nes/apu/unit/length_counter_unit_state.dart';

TriangleChannelState buildState({int timer = 2047, int timerPeriod = 1234}) {
  return TriangleChannelState(
    enabled: true,
    control: false,
    dutyIndex: 17,
    linearCounterPeriod: 0x55,
    linearCounter: 0x2a,
    timer: timer,
    timerPeriod: timerPeriod,
    reload: true,
    lengthCounterState: const LengthCounterUnitState(halt: true, value: 254),
  );
}

void expectStatesEqual(
  TriangleChannelState actual,
  TriangleChannelState expected,
) {
  expect(actual.enabled, expected.enabled);
  expect(actual.control, expected.control);
  expect(actual.dutyIndex, expected.dutyIndex);
  expect(actual.linearCounterPeriod, expected.linearCounterPeriod);
  expect(actual.linearCounter, expected.linearCounter);
  expect(actual.timer, expected.timer);
  expect(actual.timerPeriod, expected.timerPeriod);
  expect(actual.reload, expected.reload);
  expect(actual.lengthCounterState.halt, expected.lengthCounterState.halt);
  expect(actual.lengthCounterState.value, expected.lengthCounterState.value);
}

void main() {
  test('serialize writes version 1 and round-trips 11-bit timer values', () {
    final original = buildState();

    final writer = Payload.write();
    original.serialize(writer);
    final bytes = binarize(writer);

    expect(bytes[0], 1, reason: 'TriangleChannelState version');

    final decoded = TriangleChannelState.deserialize(Payload.read(bytes));

    expectStatesEqual(decoded, original);
  });

  test('still reads legacy version 0 payloads', () {
    final original = buildState(timer: 200, timerPeriod: 150);

    // replicate the exact v0 wire format the previous code produced
    final writer = Payload.write()
      ..set(uint8, 0)
      ..set(boolean, original.enabled)
      ..set(boolean, original.control)
      ..set(uint8, original.dutyIndex)
      ..set(uint8, original.linearCounterPeriod)
      ..set(uint8, original.linearCounter)
      ..set(uint8, original.timer)
      ..set(uint8, original.timerPeriod)
      ..set(boolean, original.reload);

    original.lengthCounterState.serialize(writer);

    final decoded = TriangleChannelState.deserialize(
      Payload.read(binarize(writer)),
    );

    expectStatesEqual(decoded, original);
  });
}
