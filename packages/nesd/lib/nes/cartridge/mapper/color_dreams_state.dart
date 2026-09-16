import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class ColorDreamsState extends MapperState {
  const ColorDreamsState({
    required this.prgBank,
    required this.chrBank,
    super.id = 11,
  });

  factory ColorDreamsState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => ColorDreamsState._version0(reader),
      _ => throw InvalidSerializationVersion('ColorDreams', version),
    };
  }

  factory ColorDreamsState._version0(PayloadReader reader) {
    return ColorDreamsState(
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
