import 'dart:typed_data';

import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class SinglePrgBankState extends MapperState {
  const SinglePrgBankState({
    required super.id,
    required this.prgBank,
  });

  factory SinglePrgBankState.fromByteData(int id, ByteData data, int offset) {
    return SinglePrgBankState(
      id: id,
      prgBank: data.getUint8(offset),
    );
  }

  final int prgBank;

  @override
  int get byteLength => 1;

  @override
  void toByteData(ByteData data, int offset) {
    data.setUint8(offset, prgBank);
  }
}
