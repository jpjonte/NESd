import 'dart:typed_data';

import 'package:nes/nes/cartridge/mapper/mapper_state.dart';

class MMC1State extends MapperState {
  const MMC1State({
    required this.shift,
    required this.control,
    required this.chrBank0,
    required this.chrBank1,
    required this.prgBank,
    super.id = 1,
  });

  factory MMC1State.fromByteData(ByteData data, int offset) {
    return MMC1State(
      shift: data.getUint8(offset),
      control: data.getUint8(offset + 1),
      chrBank0: data.getUint8(offset + 2),
      chrBank1: data.getUint8(offset + 3),
      prgBank: data.getUint8(offset + 4),
    );
  }

  final int shift;

  final int control;

  final int chrBank0;
  final int chrBank1;

  final int prgBank;

  @override
  int get byteLength => 5;

  @override
  void toByteData(ByteData data, int offset) {
    data
      ..setUint8(offset, shift)
      ..setUint8(offset + 1, control)
      ..setUint8(offset + 2, chrBank0)
      ..setUint8(offset + 3, chrBank1)
      ..setUint8(offset + 4, prgBank);
  }
}
