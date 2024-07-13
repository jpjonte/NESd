import 'package:binarize/binarize.dart';
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
}

class _TriangleChannelStateContract extends BinaryContract<TriangleChannelState>
    implements TriangleChannelState {
  const _TriangleChannelStateContract()
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
      type(lengthCounterUnitStateContract, (o) => o.lengthCounterState);
}

const triangleChannelStateContract = _TriangleChannelStateContract();
