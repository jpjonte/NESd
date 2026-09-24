import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class NINA003006State extends MapperState {
  const NINA003006State({
    required this.prgBank,
    required this.chrBank,
    super.id = 79,
  });

  factory NINA003006State.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => NINA003006State._version0(reader),
      _ => throw InvalidSerializationVersion('NINA-003-006', version),
    };
  }

  factory NINA003006State._version0(PayloadReader reader) {
    return NINA003006State(
      prgBank: reader.get(uint8),
      chrBank: reader.get(uint8),
    );
  }

  final int prgBank;
  final int chrBank;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(uint8, prgBank)
      ..set(uint8, chrBank);
  }
}
