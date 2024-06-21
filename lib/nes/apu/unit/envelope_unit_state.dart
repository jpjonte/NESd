import 'package:binarize/binarize.dart';

class EnvelopeUnitState {
  const EnvelopeUnitState({
    required this.volume,
    required this.period,
    required this.timer,
    required this.start,
    required this.loop,
  });

  const EnvelopeUnitState.dummy()
      : volume = 0,
        period = 0,
        timer = 0,
        start = false,
        loop = false;

  final int volume;
  final int period;
  final int timer;
  final bool start;
  final bool loop;
}

class _EnvelopeUnitStateContract extends BinaryContract<EnvelopeUnitState>
    implements EnvelopeUnitState {
  const _EnvelopeUnitStateContract()
      : super(
          const EnvelopeUnitState.dummy(),
        );

  @override
  EnvelopeUnitState order(EnvelopeUnitState contract) {
    return EnvelopeUnitState(
      volume: contract.volume,
      period: contract.period,
      timer: contract.timer,
      start: contract.start,
      loop: contract.loop,
    );
  }

  @override
  int get volume => type(uint8, (o) => o.volume);

  @override
  int get period => type(uint8, (o) => o.period);

  @override
  int get timer => type(uint8, (o) => o.timer);

  @override
  bool get start => type(boolean, (o) => o.start);

  @override
  bool get loop => type(boolean, (o) => o.loop);
}

const envelopeUnitStateContract = _EnvelopeUnitStateContract();
