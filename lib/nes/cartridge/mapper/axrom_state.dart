import 'dart:typed_data';

import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class AXROMState extends MapperState {
  const AXROMState({
    required this.prgBank,
    required this.vramBank,
    super.id = 7,
  });

  factory AXROMState.fromByteData(ByteData data, int offset) {
    return AXROMState(
      prgBank: data.getUint8(offset),
      vramBank: data.getUint8(offset + 1),
    );
  }

  final int prgBank;

  final int vramBank;

  @override
  int get byteLength => 2;

  @override
  void toByteData(ByteData data, int offset) {
    data
      ..setUint8(offset, prgBank)
      ..setUint8(offset + 1, vramBank);
  }
}
