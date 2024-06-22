import 'dart:typed_data';

import 'package:nes/nes/cartridge/mapper/mapper_state.dart';

class AXROMState extends MapperState {
  const AXROMState({
    required this.prgBank,
    required this.chrBank,
    super.id = 7,
  });

  factory AXROMState.fromByteData(ByteData data, int offset) {
    return AXROMState(
      prgBank: data.getUint8(offset),
      chrBank: data.getUint8(offset + 1),
    );
  }

  final int prgBank;

  final int chrBank;

  @override
  int get byteLength => 2;

  @override
  void toByteData(ByteData data, int offset) {
    data
      ..setUint8(offset, prgBank)
      ..setUint8(offset + 1, chrBank);
  }
}
