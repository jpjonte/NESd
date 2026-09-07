import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';

class LengthCounterUnitState {
  const LengthCounterUnitState({
    required this.halt,
    required this.value,
    this.pendingHalt,
    this.pendingValue,
  });

  factory LengthCounterUnitState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => LengthCounterUnitState._version0(reader),
      1 => LengthCounterUnitState._version1(reader),
      _ => throw InvalidSerializationVersion('LengthCounterUnitState', version),
    };
  }

  factory LengthCounterUnitState._version0(PayloadReader reader) {
    return LengthCounterUnitState(
      halt: reader.get(boolean),
      value: reader.get(uint8),
    );
  }

  factory LengthCounterUnitState._version1(PayloadReader reader) {
    final halt = reader.get(boolean);
    final value = reader.get(uint8);
    final pendingHalt = reader.get(uint8);
    final pendingValue = reader.get(uint8);

    return LengthCounterUnitState(
      halt: halt,
      value: value,
      pendingHalt: switch (pendingHalt) {
        _noPendingHalt => null,
        _ => pendingHalt == 1,
      },
      pendingValue: pendingValue == _noPendingValue ? null : pendingValue,
    );
  }

  static const _noPendingHalt = 2;
  static const _noPendingValue = 0xff;

  final bool halt;

  final int value;

  /// A halt flag written last cycle and not yet in effect.
  final bool? pendingHalt;

  /// A reload written last cycle and not yet in effect.
  final int? pendingValue;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 1) // version
      ..set(boolean, halt)
      ..set(uint8, value)
      ..set(uint8, switch (pendingHalt) {
        null => _noPendingHalt,
        true => 1,
        false => 0,
      })
      ..set(uint8, pendingValue ?? _noPendingValue);
  }
}
