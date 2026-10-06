import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class NanjingFC001State extends MapperState {
  const NanjingFC001State({
    required this.prgLow,
    required this.feedback,
    required this.prgHigh,
    required this.mode,
    required this.pa09,
    required this.pa13,
    super.id = 163,
  });

  factory NanjingFC001State.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => NanjingFC001State._version0(reader),
      _ => throw InvalidSerializationVersion('NanjingFC001', version),
    };
  }

  factory NanjingFC001State._version0(PayloadReader reader) {
    return NanjingFC001State(
      prgLow: reader.get(uint8),
      feedback: reader.get(uint8),
      prgHigh: reader.get(uint8),
      mode: reader.get(uint8),
      pa09: reader.get(boolean),
      pa13: reader.get(boolean),
    );
  }

  final int prgLow;
  final int feedback;
  final int prgHigh;
  final int mode;

  final bool pa09;
  final bool pa13;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(uint8, prgLow)
      ..set(uint8, feedback)
      ..set(uint8, prgHigh)
      ..set(uint8, mode)
      ..set(boolean, pa09)
      ..set(boolean, pa13);
  }
}
