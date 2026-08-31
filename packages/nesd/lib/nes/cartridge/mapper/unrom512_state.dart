import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class UNROM512State extends MapperState {
  const UNROM512State({required this.latch}) : super(id: 30);

  factory UNROM512State.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => UNROM512State._version0(reader),
      _ => throw InvalidSerializationVersion('UNROM512State', version),
    };
  }

  factory UNROM512State._version0(PayloadReader reader) {
    return UNROM512State(latch: reader.get(uint8));
  }

  final int latch;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(uint8, latch);
  }
}
