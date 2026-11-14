import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class Mapper185State extends MapperState {
  const Mapper185State({
    required this.latch,
    required this.disabledReads,
    super.id = 185,
  });

  factory Mapper185State.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => Mapper185State._version0(reader),
      _ => throw InvalidSerializationVersion('Mapper185', version),
    };
  }

  factory Mapper185State._version0(PayloadReader reader) {
    return Mapper185State(
      latch: reader.get(uint8),
      disabledReads: reader.get(uint8),
    );
  }

  final int latch;
  final int disabledReads;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(uint8, latch)
      ..set(uint8, disabledReads);
  }
}
