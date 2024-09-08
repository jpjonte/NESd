import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';

class EnvelopeUnitState {
  const EnvelopeUnitState({
    required this.volume,
    required this.period,
    required this.timer,
    required this.start,
    required this.loop,
  });

  factory EnvelopeUnitState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => EnvelopeUnitState._version0(reader),
      _ => throw InvalidSerializationVersion('EnvelopeUnitState', version),
    };
  }

  factory EnvelopeUnitState._version0(PayloadReader reader) {
    return EnvelopeUnitState(
      volume: reader.get(uint8),
      period: reader.get(uint8),
      timer: reader.get(uint8),
      start: reader.get(boolean),
      loop: reader.get(boolean),
    );
  }

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

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 0) // version
      ..set(uint8, volume)
      ..set(uint8, period)
      ..set(uint8, timer)
      ..set(boolean, start)
      ..set(boolean, loop);
  }
}

class _LegacyEnvelopeUnitStateContract extends BinaryContract<EnvelopeUnitState>
    implements EnvelopeUnitState {
  const _LegacyEnvelopeUnitStateContract()
      : super(const EnvelopeUnitState.dummy());

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

  @override
  void serialize(PayloadWriter writer) => throw UnimplementedError();
}

const legacyEnvelopeUnitStateContract = _LegacyEnvelopeUnitStateContract();
