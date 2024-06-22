import 'package:binarize/binarize.dart';

class LengthCounterUnitState {
  const LengthCounterUnitState({
    required this.halt,
    required this.value,
  });

  const LengthCounterUnitState.dummy()
      : halt = false,
        value = 0;

  final bool halt;

  final int value;
}

class _LengthCounterUnitStateContract
    extends BinaryContract<LengthCounterUnitState>
    implements LengthCounterUnitState {
  const _LengthCounterUnitStateContract()
      : super(const LengthCounterUnitState.dummy());

  @override
  LengthCounterUnitState order(LengthCounterUnitState contract) {
    return LengthCounterUnitState(
      halt: contract.halt,
      value: contract.value,
    );
  }

  @override
  bool get halt => type(boolean, (o) => o.halt);

  @override
  int get value => type(uint8, (o) => o.value);
}

const lengthCounterUnitStateContract = _LengthCounterUnitStateContract();
