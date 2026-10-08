import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class BandaiDiscreteState extends MapperState {
  const BandaiDiscreteState({
    required this.prgBank,
    required this.chrBank,
    required this.nametable,
    required super.id,
  });

  factory BandaiDiscreteState.deserialize(PayloadReader reader, int id) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => BandaiDiscreteState._version0(reader, id),
      _ => throw InvalidSerializationVersion('BandaiDiscrete', version),
    };
  }

  factory BandaiDiscreteState._version0(PayloadReader reader, int id) {
    return BandaiDiscreteState(
      id: id,
      prgBank: reader.get(uint8),
      chrBank: reader.get(uint8),
      nametable: reader.get(uint8),
    );
  }

  final int prgBank;
  final int chrBank;
  final int nametable;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(uint8, prgBank)
      ..set(uint8, chrBank)
      ..set(uint8, nametable);
  }
}
