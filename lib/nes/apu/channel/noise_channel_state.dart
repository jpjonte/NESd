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

  const NoiseChannelState.dummy()
      : this(
          enabled: false,
          constantVolume: false,
          volume: 0,
          period: 0,
          timerPeriod: 0,
          timer: 0,
          shiftRegister: 1,
          mode: false,
          envelopeState: const EnvelopeUnitState.dummy(),
          lengthCounterState: const LengthCounterUnitState.dummy(),
        );

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

class _LegacyNoiseChannelStateContract extends BinaryContract<NoiseChannelState>
    implements NoiseChannelState {
  const _LegacyNoiseChannelStateContract()
      : super(const NoiseChannelState.dummy());

  @override
  NoiseChannelState order(NoiseChannelState contract) {
    return NoiseChannelState(
      enabled: contract.enabled,
      constantVolume: contract.constantVolume,
      volume: contract.volume,
      period: contract.period,
      timerPeriod: contract.timerPeriod,
      timer: contract.timer,
      shiftRegister: contract.shiftRegister,
      mode: contract.mode,
      envelopeState: contract.envelopeState,
      lengthCounterState: contract.lengthCounterState,
    );
  }

  @override
  bool get enabled => type(boolean, (o) => o.enabled);

  @override
  bool get constantVolume => type(boolean, (o) => o.constantVolume);

  @override
  int get volume => type(uint8, (o) => o.volume);

  @override
  int get period => type(uint8, (o) => o.period);

  @override
  int get timerPeriod => type(uint8, (o) => o.timerPeriod);

  @override
  int get timer => type(uint8, (o) => o.timer);

  @override
  int get shiftRegister => type(uint8, (o) => o.shiftRegister);

  @override
  bool get mode => type(boolean, (o) => o.mode);

  @override
  EnvelopeUnitState get envelopeState => type(
        legacyEnvelopeUnitStateContract,
        (o) => o.envelopeState,
      );

  @override
  LengthCounterUnitState get lengthCounterState => type(
        legacyLengthCounterUnitStateContract,
        (o) => o.lengthCounterState,
      );

  @override
  void serialize(PayloadWriter writer) => throw UnimplementedError();
}

const legacyNoiseChannelStateContract = _LegacyNoiseChannelStateContract();
