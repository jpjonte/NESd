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

  const SweepUnitState.dummy()
      : enabled = false,
        muting = false,
        value = 0,
        period = 0,
        shift = 0,
        negate = false,
        reload = false;

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

class _LegacySweepUnitStateContract extends BinaryContract<SweepUnitState>
    implements SweepUnitState {
  const _LegacySweepUnitStateContract() : super(const SweepUnitState.dummy());

  @override
  SweepUnitState order(SweepUnitState contract) {
    return SweepUnitState(
      enabled: contract.enabled,
      muting: contract.muting,
      value: contract.value,
      period: contract.period,
      shift: contract.shift,
      negate: contract.negate,
      reload: contract.reload,
    );
  }

  @override
  bool get enabled => type(boolean, (o) => o.enabled);

  @override
  bool get muting => type(boolean, (o) => o.muting);

  @override
  int get value => type(uint8, (o) => o.value);

  @override
  int get period => type(uint8, (o) => o.period);

  @override
  int get shift => type(uint8, (o) => o.shift);

  @override
  bool get negate => type(boolean, (o) => o.negate);

  @override
  bool get reload => type(boolean, (o) => o.reload);

  @override
  void serialize(PayloadWriter writer) => throw UnimplementedError();
}

const legacySweepUnitStateContract = _LegacySweepUnitStateContract();
