import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';

class FrameCounterState {
  const FrameCounterState({
    required this.counter,
    required this.fiveStep,
    required this.interrupt,
    required this.interruptInhibit,
  });

  factory FrameCounterState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => FrameCounterState._version0(reader),
      1 => FrameCounterState._version1(reader),
      _ => throw InvalidSerializationVersion('FrameCounterState', version),
    };
  }

  factory FrameCounterState._version0(PayloadReader reader) {
    return FrameCounterState(
      counter: reader.get(uint8),
      fiveStep: reader.get(boolean),
      interrupt: reader.get(boolean),
      interruptInhibit: reader.get(boolean),
    );
  }

  factory FrameCounterState._version1(PayloadReader reader) {
    return FrameCounterState(
      counter: reader.get(uint16),
      fiveStep: reader.get(boolean),
      interrupt: reader.get(boolean),
      interruptInhibit: reader.get(boolean),
    );
  }

  final int counter;

  final bool fiveStep;

  final bool interrupt;
  final bool interruptInhibit;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 1) // version
      ..set(uint16, counter)
      ..set(boolean, fiveStep)
      ..set(boolean, interrupt)
      ..set(boolean, interruptInhibit);
  }
}
