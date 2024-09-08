import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/apu/unit/length_counter_unit_state.dart';

class TriangleChannelState {
  const TriangleChannelState({
    required this.enabled,
    required this.control,
    required this.dutyIndex,
    required this.linearCounterPeriod,
    required this.linearCounter,
    required this.timer,
    required this.timerPeriod,
    required this.reload,
    required this.lengthCounterState,
  });

  factory TriangleChannelState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => TriangleChannelState._version0(reader),
      _ => throw InvalidSerializationVersion('TriangleChannelState', version),
    };
  }

  factory TriangleChannelState._version0(PayloadReader reader) {
    return TriangleChannelState(
      enabled: reader.get(boolean),
      control: reader.get(boolean),
      dutyIndex: reader.get(uint8),
      linearCounterPeriod: reader.get(uint8),
      linearCounter: reader.get(uint8),
      timer: reader.get(uint8),
      timerPeriod: reader.get(uint8),
      reload: reader.get(boolean),
      lengthCounterState: LengthCounterUnitState.deserialize(reader),
    );
  }

  const TriangleChannelState.dummy()
      : this(
          enabled: false,
          control: false,
          dutyIndex: 0,
          linearCounterPeriod: 0,
          linearCounter: 0,
          timer: 0,
          timerPeriod: 0,
          reload: false,
          lengthCounterState: const LengthCounterUnitState.dummy(),
        );

  final bool enabled;

  final bool control;

  final int dutyIndex;

  final int linearCounterPeriod;
  final int linearCounter;

  final int timer;
  final int timerPeriod;

  final bool reload;

  final LengthCounterUnitState lengthCounterState;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 0) // version
      ..set(boolean, enabled)
      ..set(boolean, control)
      ..set(uint8, dutyIndex)
      ..set(uint8, linearCounterPeriod)
      ..set(uint8, linearCounter)
      ..set(uint8, timer)
      ..set(uint8, timerPeriod)
      ..set(boolean, reload);

    lengthCounterState.serialize(writer);
  }
}

class _LegacyTriangleChannelStateContract
    extends BinaryContract<TriangleChannelState>
    implements TriangleChannelState {
  const _LegacyTriangleChannelStateContract()
      : super(const TriangleChannelState.dummy());

  @override
  TriangleChannelState order(TriangleChannelState contract) {
    return TriangleChannelState(
      enabled: contract.enabled,
      control: contract.control,
      dutyIndex: contract.dutyIndex,
      linearCounterPeriod: contract.linearCounterPeriod,
      linearCounter: contract.linearCounter,
      timer: contract.timer,
      timerPeriod: contract.timerPeriod,
      reload: contract.reload,
      lengthCounterState: contract.lengthCounterState,
    );
  }

  @override
  bool get enabled => type(boolean, (o) => o.enabled);

  @override
  bool get control => type(boolean, (o) => o.control);

  @override
  int get dutyIndex => type(uint8, (o) => o.dutyIndex);

  @override
  int get linearCounterPeriod => type(uint8, (o) => o.linearCounterPeriod);

  @override
  int get linearCounter => type(uint8, (o) => o.linearCounter);

  @override
  int get timer => type(uint8, (o) => o.timer);

  @override
  int get timerPeriod => type(uint8, (o) => o.timerPeriod);

  @override
  bool get reload => type(boolean, (o) => o.reload);

  @override
  LengthCounterUnitState get lengthCounterState =>
      type(legacyLengthCounterUnitStateContract, (o) => o.lengthCounterState);

  @override
  void serialize(PayloadWriter writer) => throw UnimplementedError();
}

const legacyTriangleChannelStateContract =
    _LegacyTriangleChannelStateContract();
