import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class Mapper34State extends MapperState {
  const Mapper34State({
    required this.prgBank,
    required this.chrBank0,
    required this.chrBank1,
    required super.id,
  });

  factory Mapper34State.deserialize(PayloadReader reader, int id) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => Mapper34State._version0(reader, id),
      _ => throw InvalidSerializationVersion('Mapper34', version),
    };
  }

  factory Mapper34State._version0(PayloadReader reader, int id) {
    return Mapper34State(
      id: id,
      prgBank: reader.get(uint8),
      chrBank0: reader.get(uint8),
      chrBank1: reader.get(uint8),
    );
  }

  final int prgBank;
  final int chrBank0;
  final int chrBank1;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(uint8, prgBank)
      ..set(uint8, chrBank0)
      ..set(uint8, chrBank1);
  }
}
