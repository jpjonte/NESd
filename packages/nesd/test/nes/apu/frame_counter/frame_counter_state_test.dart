import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/frame_counter/frame_counter_state.dart';

FrameCounterState buildState({int counter = 20781, int resetDelay = 0}) {
  return FrameCounterState(
    counter: counter,
    resetDelay: resetDelay,
    fiveStep: true,
    interrupt: false,
    interruptInhibit: true,
  );
}

void expectStatesEqual(FrameCounterState actual, FrameCounterState expected) {
  expect(actual.counter, expected.counter);
  expect(actual.resetDelay, expected.resetDelay);
  expect(actual.fiveStep, expected.fiveStep);
  expect(actual.interrupt, expected.interrupt);
  expect(actual.interruptInhibit, expected.interruptInhibit);
}

void main() {
  test('serialize writes version 2 and round-trips sequencer positions', () {
    final original = buildState(counter: 37281, resetDelay: 3);

    final writer = Payload.write();
    original.serialize(writer);
    final bytes = binarize(writer);

    expect(bytes[0], 2, reason: 'FrameCounterState version');

    final decoded = FrameCounterState.deserialize(Payload.read(bytes));

    expectStatesEqual(decoded, original);
  });

  test('still reads legacy version 0 payloads, converting APU cycles', () {
    // replicate the exact v0 wire format the previous code produced
    final writer = Payload.write()
      ..set(uint8, 0)
      ..set(uint8, 200)
      ..set(boolean, true)
      ..set(boolean, false)
      ..set(boolean, true);

    final decoded = FrameCounterState.deserialize(
      Payload.read(binarize(writer)),
    );

    expectStatesEqual(decoded, buildState(counter: 400));
  });

  test('still reads legacy version 1 payloads, converting APU cycles', () {
    // replicate the exact v1 wire format the previous code produced
    final writer = Payload.write()
      ..set(uint8, 1)
      ..set(uint16, 14914)
      ..set(boolean, true)
      ..set(boolean, false)
      ..set(boolean, true);

    final decoded = FrameCounterState.deserialize(
      Payload.read(binarize(writer)),
    );

    expectStatesEqual(decoded, buildState(counter: 29828));
  });
}
