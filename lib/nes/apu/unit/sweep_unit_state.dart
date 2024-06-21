import 'package:binarize/binarize.dart';

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
}

class _SweepUnitStateContract extends BinaryContract<SweepUnitState>
    implements SweepUnitState {
  const _SweepUnitStateContract() : super(const SweepUnitState.dummy());

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
}

const sweepUnitStateContract = _SweepUnitStateContract();
