import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/frame_counter/frame_counter_state.dart';

FrameCounterState buildState({int counter = 20781}) {
  return FrameCounterState(
    counter: counter,
    fiveStep: true,
    interrupt: false,
    interruptInhibit: true,
  );
}

void expectStatesEqual(FrameCounterState actual, FrameCounterState expected) {
  expect(actual.counter, expected.counter);
  expect(actual.fiveStep, expected.fiveStep);
  expect(actual.interrupt, expected.interrupt);
  expect(actual.interruptInhibit, expected.interruptInhibit);
}

void main() {
  test('serialize writes version 1 and round-trips sequencer positions', () {
    final original = buildState();

    final writer = Payload.write();
    original.serialize(writer);
    final bytes = binarize(writer);

    expect(bytes[0], 1, reason: 'FrameCounterState version');

    final decoded = FrameCounterState.deserialize(Payload.read(bytes));

    expectStatesEqual(decoded, original);
  });

  test('still reads legacy version 0 payloads', () {
    final original = buildState(counter: 200);

    // replicate the exact v0 wire format the previous code produced
    final writer = Payload.write()
      ..set(uint8, 0)
      ..set(uint8, original.counter)
      ..set(boolean, original.fiveStep)
      ..set(boolean, original.interrupt)
      ..set(boolean, original.interruptInhibit);

    final decoded = FrameCounterState.deserialize(
      Payload.read(binarize(writer)),
    );

    expectStatesEqual(decoded, original);
  });
}
