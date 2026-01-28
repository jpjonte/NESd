import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/apu/unit/envelope_unit_state.dart';
import 'package:nesd/nes/apu/unit/length_counter_unit_state.dart';
import 'package:nesd/nes/apu/unit/sweep_unit_state.dart';

class PulseChannelState {
  const PulseChannelState({
    required this.enabled,
    required this.duty,
    required this.constantVolume,
    required this.volume,
    required this.dutyIndex,
    required this.timer,
    required this.timerPeriod,
    required this.envelopeState,
    required this.lengthCounterState,
    required this.sweepState,
  });

  factory PulseChannelState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => PulseChannelState._version0(reader),
      _ => throw InvalidSerializationVersion('PulseChannelState', version),
    };
  }

  factory PulseChannelState._version0(PayloadReader reader) {
    return PulseChannelState(
      enabled: reader.get(boolean),
      duty: reader.get(uint8),
      constantVolume: reader.get(boolean),
      volume: reader.get(uint8),
      dutyIndex: reader.get(uint8),
      timer: reader.get(uint16),
      timerPeriod: reader.get(uint16),
      envelopeState: EnvelopeUnitState.deserialize(reader),
      lengthCounterState: LengthCounterUnitState.deserialize(reader),
      sweepState: SweepUnitState.deserialize(reader),
    );
  }

  final bool enabled;

  final int duty;

  final bool constantVolume;

  final int volume;

  final int dutyIndex;

  final int timer;
  final int timerPeriod;

  final EnvelopeUnitState envelopeState;

  final LengthCounterUnitState lengthCounterState;

  final SweepUnitState sweepState;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 0) // version
      ..set(boolean, enabled)
      ..set(uint8, duty)
      ..set(boolean, constantVolume)
      ..set(uint8, volume)
      ..set(uint8, dutyIndex)
      ..set(uint16, timer)
      ..set(uint16, timerPeriod);

    envelopeState.serialize(writer);
    lengthCounterState.serialize(writer);
    sweepState.serialize(writer);
  }
}
