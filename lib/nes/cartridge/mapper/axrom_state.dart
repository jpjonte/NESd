import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class AXROMState extends MapperState {
  const AXROMState({
    required this.prgBank,
    required this.vramBank,
    super.id = 7,
  });

  factory AXROMState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => AXROMState.version0(reader),
      _ => throw InvalidSerializationVersion('AXROM', version),
    };
  }

  factory AXROMState.version0(PayloadReader reader) {
    return AXROMState(prgBank: reader.get(uint8), vramBank: reader.get(uint8));
  }

  final int prgBank;

  final int vramBank;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(uint8, prgBank)
      ..set(uint8, vramBank);
  }
}
