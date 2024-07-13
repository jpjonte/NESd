import 'dart:typed_data';

import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class CNROMState extends MapperState {
  const CNROMState({
    required this.chrBank,
    super.id = 3,
  });

  factory CNROMState.fromByteData(ByteData data, int offset) {
    return CNROMState(
      chrBank: data.getUint8(offset),
    );
  }

  final int chrBank;

  @override
  int get byteLength => 1;

  @override
  void toByteData(ByteData data, int offset) {
    data.setUint8(offset, chrBank);
  }
}
