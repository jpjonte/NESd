import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';

class SweepUnitState {
  const SweepUnitState({
    required this.enabled,
    required this.muting,
    required this.value,
    required this.period,
    required this.shift,
    required this.negate,
    required this.reload,
  });

  factory SweepUnitState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => SweepUnitState._version0(reader),
      _ => throw InvalidSerializationVersion('SweepUnitState', version),
    };
  }

  factory SweepUnitState._version0(PayloadReader reader) {
    return SweepUnitState(
      enabled: reader.get(boolean),
      muting: reader.get(boolean),
      value: reader.get(uint8),
      period: reader.get(uint8),
      shift: reader.get(uint8),
      negate: reader.get(boolean),
      reload: reader.get(boolean),
    );
  }

  final bool enabled;
  final bool muting;

  final int value;
  final int period;
  final int shift;

  final bool negate;
  final bool reload;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 0) // version
      ..set(boolean, enabled)
      ..set(boolean, muting)
      ..set(uint8, value)
      ..set(uint8, period)
      ..set(uint8, shift)
      ..set(boolean, negate)
      ..set(boolean, reload);
  }
}
