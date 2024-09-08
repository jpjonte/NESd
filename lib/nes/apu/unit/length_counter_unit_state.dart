import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';

class LengthCounterUnitState {
  const LengthCounterUnitState({
    required this.halt,
    required this.value,
  });

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

  const LengthCounterUnitState.dummy()
      : halt = false,
        value = 0;

  final bool halt;

  final int value;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 0) // version
      ..set(boolean, halt)
      ..set(uint8, value);
  }
}

class _LegacyLengthCounterUnitStateContract
    extends BinaryContract<LengthCounterUnitState>
    implements LengthCounterUnitState {
  const _LegacyLengthCounterUnitStateContract()
      : super(const LengthCounterUnitState.dummy());

  @override
  LengthCounterUnitState order(LengthCounterUnitState contract) {
    return LengthCounterUnitState(
      halt: contract.halt,
      value: contract.value,
    );
  }

  @override
  bool get halt => type(boolean, (o) => o.halt);

  @override
  int get value => type(uint8, (o) => o.value);

  @override
  void serialize(PayloadWriter writer) => throw UnimplementedError();
}

const legacyLengthCounterUnitStateContract =
    _LegacyLengthCounterUnitStateContract();
