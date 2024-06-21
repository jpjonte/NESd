import 'package:binarize/binarize.dart';

class FrameCounterState {
  const FrameCounterState({
    required this.counter,
    required this.fiveStep,
    required this.interrupt,
    required this.interruptInhibit,
  });

  const FrameCounterState.dummy()
      : counter = 0,
        fiveStep = false,
        interrupt = false,
        interruptInhibit = false;

  final int counter;

  final bool fiveStep;

  final bool interrupt;
  final bool interruptInhibit;
}

class _FrameCounterStateContract extends BinaryContract<FrameCounterState>
    implements FrameCounterState {
  const _FrameCounterStateContract() : super(const FrameCounterState.dummy());

  @override
  FrameCounterState order(FrameCounterState contract) {
    return FrameCounterState(
      counter: contract.counter,
      fiveStep: contract.fiveStep,
      interrupt: contract.interrupt,
      interruptInhibit: contract.interruptInhibit,
    );
  }

  @override
  int get counter => type(uint8, (o) => o.counter);

  @override
  bool get fiveStep => type(boolean, (o) => o.fiveStep);

  @override
  bool get interrupt => type(boolean, (o) => o.interrupt);

  @override
  bool get interruptInhibit => type(boolean, (o) => o.interruptInhibit);
}

const frameCounterStateContract = _FrameCounterStateContract();
