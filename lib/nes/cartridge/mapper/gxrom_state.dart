import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class GxROMState extends MapperState {
  const GxROMState({
    required this.prgBank,
    required this.chrBank,
    super.id = 66,
  });

  factory GxROMState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => GxROMState._version0(reader),
      _ => throw InvalidSerializationVersion('GxROM', version),
    };
  }

  factory GxROMState._version0(PayloadReader reader) {
    return GxROMState(
      prgBank: reader.get(uint8),
      chrBank: reader.get(uint8),
    );
  }

  factory GxROMState.legacyFromByteData(ByteData data, int offset) {
    final version = data.getUint8(offset);

    return switch (version) {
      0 => GxROMState.version0(data, offset + 1),
      _ => throw InvalidSerializationVersion('GxROM', version),
    };
  }

  factory GxROMState.version0(ByteData data, int offset) {
    return GxROMState(
      prgBank: data.getUint8(offset),
      chrBank: data.getUint8(offset + 1),
    );
  }

  final int chrBank;
  final int prgBank;

  @override
  int get byteLength => 3;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(uint8, prgBank)
      ..set(uint8, chrBank);
  }
}
