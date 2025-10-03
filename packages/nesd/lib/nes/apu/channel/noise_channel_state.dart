import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/apu/unit/envelope_unit_state.dart';
import 'package:nesd/nes/apu/unit/length_counter_unit_state.dart';

class NoiseChannelState {
  const NoiseChannelState({
    required this.enabled,
    required this.constantVolume,
    required this.volume,
    required this.period,
    required this.timerPeriod,
    required this.timer,
    required this.shiftRegister,
    required this.mode,
    required this.envelopeState,
    required this.lengthCounterState,
  });

  factory NoiseChannelState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => NoiseChannelState._version0(reader),
      _ => throw InvalidSerializationVersion('NoiseChannelState', version),
    };
  }

  factory NoiseChannelState._version0(PayloadReader reader) {
    return NoiseChannelState(
      enabled: reader.get(boolean),
      constantVolume: reader.get(boolean),
      volume: reader.get(uint8),
      period: reader.get(uint8),
      timerPeriod: reader.get(uint8),
      timer: reader.get(uint8),
      shiftRegister: reader.get(uint8),
      mode: reader.get(boolean),
      envelopeState: EnvelopeUnitState.deserialize(reader),
      lengthCounterState: LengthCounterUnitState.deserialize(reader),
    );
  }

  final bool enabled;

  final bool constantVolume;
  final int volume;

  final int period;

  final int timerPeriod;
  final int timer;

  final int shiftRegister;

  final bool mode;

  final EnvelopeUnitState envelopeState;
  final LengthCounterUnitState lengthCounterState;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 0) // version
      ..set(boolean, enabled)
      ..set(boolean, constantVolume)
      ..set(uint8, volume)
      ..set(uint8, period)
      ..set(uint8, timerPeriod)
      ..set(uint8, timer)
      ..set(uint8, shiftRegister)
      ..set(boolean, mode);

    envelopeState.serialize(writer);
    lengthCounterState.serialize(writer);
  }
}
