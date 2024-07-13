import 'package:binarize/binarize.dart';
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
}

class _NoiseChannelStateContract extends BinaryContract<NoiseChannelState>
    implements NoiseChannelState {
  const _NoiseChannelStateContract() : super(const NoiseChannelState.dummy());

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
        envelopeUnitStateContract,
        (o) => o.envelopeState,
      );

  @override
  LengthCounterUnitState get lengthCounterState => type(
        lengthCounterUnitStateContract,
        (o) => o.lengthCounterState,
      );
}

const noiseChannelStateContract = _NoiseChannelStateContract();
