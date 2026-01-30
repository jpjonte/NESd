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
