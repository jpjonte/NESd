import 'package:binarize/binarize.dart';
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

  const PulseChannelState.dummy()
      : this(
          enabled: false,
          duty: 0,
          constantVolume: false,
          volume: 0,
          dutyIndex: 0,
          timer: 0,
          timerPeriod: 0,
          envelopeState: const EnvelopeUnitState.dummy(),
          lengthCounterState: const LengthCounterUnitState.dummy(),
          sweepState: const SweepUnitState.dummy(),
        );

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
}

class _PulseChannelStateContract extends BinaryContract<PulseChannelState>
    implements PulseChannelState {
  const _PulseChannelStateContract() : super(const PulseChannelState.dummy());

  @override
  PulseChannelState order(PulseChannelState contract) {
    return PulseChannelState(
      enabled: contract.enabled,
      duty: contract.duty,
      constantVolume: contract.constantVolume,
      volume: contract.volume,
      dutyIndex: contract.dutyIndex,
      timer: contract.timer,
      timerPeriod: contract.timerPeriod,
      envelopeState: contract.envelopeState,
      lengthCounterState: contract.lengthCounterState,
      sweepState: contract.sweepState,
    );
  }

  @override
  bool get enabled => type(boolean, (o) => o.enabled);

  @override
  int get duty => type(uint8, (o) => o.duty);

  @override
  bool get constantVolume => type(boolean, (o) => o.constantVolume);

  @override
  int get volume => type(uint8, (o) => o.volume);

  @override
  int get dutyIndex => type(uint8, (o) => o.dutyIndex);

  @override
  int get timer => type(uint16, (o) => o.timer);

  @override
  int get timerPeriod => type(uint16, (o) => o.timerPeriod);

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

  @override
  SweepUnitState get sweepState => type(
        sweepUnitStateContract,
        (o) => o.sweepState,
      );
}

const pulseChannelStateContract = _PulseChannelStateContract();
