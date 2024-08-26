import 'dart:typed_data';

import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class GxROMState extends MapperState {
  const GxROMState({
    required this.prgBank,
    required this.chrBank,
    super.id = 66,
  });

  factory GxROMState.fromByteData(ByteData data, int offset) {
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
  void toByteData(ByteData data, int offset) {
    data
      ..setUint8(offset, 0) // version
      ..setUint8(offset + 1, prgBank)
      ..setUint8(offset + 2, chrBank);
  }
}
