import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class MMC1State extends MapperState {
  const MMC1State({
    required this.shift,
    required this.control,
    required this.chrBank0,
    required this.chrBank1,
    required this.prgBank,
    super.id = 1,
  });

  factory MMC1State.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => MMC1State._version0(reader),
      _ => throw InvalidSerializationVersion('MMC1', version),
    };
  }

  factory MMC1State._version0(PayloadReader reader) {
    return MMC1State(
      shift: reader.get(uint8),
      control: reader.get(uint8),
      chrBank0: reader.get(uint8),
      chrBank1: reader.get(uint8),
      prgBank: reader.get(uint8),
    );
  }

  final int shift;

  final int control;

  final int chrBank0;
  final int chrBank1;

  final int prgBank;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(uint8, shift)
      ..set(uint8, control)
      ..set(uint8, chrBank0)
      ..set(uint8, chrBank1)
      ..set(uint8, prgBank);
  }
}
