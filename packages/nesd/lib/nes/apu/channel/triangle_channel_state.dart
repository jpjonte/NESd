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
