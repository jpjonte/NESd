import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class CNROMState extends MapperState {
  const CNROMState({
    required this.chrBank,
    super.id = 3,
  });

  factory CNROMState.legacyFromByteData(ByteData data, int offset) {
    return CNROMState(chrBank: data.getUint8(offset));
  }

  factory CNROMState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => CNROMState._version0(reader),
      _ => throw InvalidSerializationVersion('CNROM', version),
    };
  }

  factory CNROMState._version0(PayloadReader reader) {
    return CNROMState(chrBank: reader.get(uint8));
  }

  final int chrBank;

  @override
  int get byteLength => 1;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(uint8, chrBank);
  }
}
