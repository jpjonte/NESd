import 'dart:typed_data';

import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class MMC2State extends MapperState {
  const MMC2State({
    required this.prgBank,
    required this.chrBank0,
    required this.chrBank1,
    required this.chrLatch0,
    required this.chrLatch1,
    required this.mirroring,
    super.id = 9,
  });

  factory MMC2State.fromByteData(ByteData data, int offset) {
    final version = data.getUint8(offset);

    return switch (version) {
      0 => MMC2State.version0(data, offset + 1),
      _ => throw InvalidSerializationVersion('MMC2', version),
    };
  }

  factory MMC2State.version0(ByteData data, int offset) {
    return MMC2State(
      prgBank: data.getUint8(offset),
      chrBank0: [data.getUint8(offset + 1), data.getUint8(offset + 2)],
      chrBank1: [data.getUint8(offset + 3), data.getUint8(offset + 4)],
      chrLatch0: data.getUint8(offset + 5),
      chrLatch1: data.getUint8(offset + 6),
      mirroring: data.getUint8(offset + 7),
    );
  }

  final int prgBank;

  final List<int> chrBank0;
  final List<int> chrBank1;

  final int chrLatch0;
  final int chrLatch1;

  final int mirroring;

  @override
  int get byteLength => 9;

  @override
  void toByteData(ByteData data, int offset) {
    data
      ..setUint8(offset, 0)
      ..setUint8(offset + 1, prgBank)
      ..setUint8(offset + 2, chrBank0[0])
      ..setUint8(offset + 3, chrBank0[1])
      ..setUint8(offset + 4, chrBank1[0])
      ..setUint8(offset + 5, chrBank1[1])
      ..setUint8(offset + 6, chrLatch0)
      ..setUint8(offset + 7, chrLatch1)
      ..setUint8(offset + 8, mirroring);
  }
}