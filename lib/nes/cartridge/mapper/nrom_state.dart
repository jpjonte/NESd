import 'dart:typed_data';

import 'package:nes/nes/cartridge/mapper/mapper_state.dart';

class NROMState extends MapperState {
  const NROMState() : super(id: 0);

  @override
  int get byteLength => 0;

  @override
  void toByteData(ByteData data, int offset) {
    // No-op
  }
}
