import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';

class LengthCounterUnitState {
  const LengthCounterUnitState({required this.halt, required this.value});

  factory LengthCounterUnitState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => LengthCounterUnitState._version0(reader),
      _ => throw InvalidSerializationVersion('LengthCounterUnitState', version),
    };
  }

  factory LengthCounterUnitState._version0(PayloadReader reader) {
    return LengthCounterUnitState(
      halt: reader.get(boolean),
      value: reader.get(uint8),
    );
  }

  final bool halt;

  final int value;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 0) // version
      ..set(boolean, halt)
      ..set(uint8, value);
  }
}
