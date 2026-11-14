import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class Mapper87State extends MapperState {
  const Mapper87State({required this.chrBank, super.id = 87});

  factory Mapper87State.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => Mapper87State._version0(reader),
      _ => throw InvalidSerializationVersion('J87', version),
    };
  }

  factory Mapper87State._version0(PayloadReader reader) {
    return Mapper87State(chrBank: reader.get(uint8));
  }

  final int chrBank;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(uint8, chrBank);
  }
}
