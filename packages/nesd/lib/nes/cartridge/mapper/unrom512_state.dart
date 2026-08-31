import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class UNROM512State extends MapperState {
  const UNROM512State({required this.latch, required this.flashSectors})
    : super(id: 30);

  factory UNROM512State.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => UNROM512State._version0(reader),
      _ => throw InvalidSerializationVersion('UNROM512State', version),
    };
  }

  factory UNROM512State._version0(PayloadReader reader) {
    final latch = reader.get(uint8);
    final sectors = reader.get(list(uint16));

    return UNROM512State(
      latch: latch,
      flashSectors: {
        for (final sector in sectors)
          sector: reader.get(uint8List(lengthType: uint32)),
      },
    );
  }

  final int latch;

  final Map<int, Uint8List> flashSectors;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    final sectors = flashSectors.keys.toList()..sort();

    writer
      ..set(uint8, 0) // version
      ..set(uint8, latch)
      ..set(list(uint16), sectors);

    for (final sector in sectors) {
      writer.set(uint8List(lengthType: uint32), flashSectors[sector]!);
    }
  }
}
