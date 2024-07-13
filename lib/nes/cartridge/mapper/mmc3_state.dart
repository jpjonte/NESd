import 'dart:typed_data';

import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class MMC3State extends MapperState {
  const MMC3State({
    required this.register,
    required this.r0,
    required this.r1,
    required this.r2,
    required this.r3,
    required this.r4,
    required this.r5,
    required this.r6,
    required this.r7,
    required this.prgBankMode,
    required this.chrBankMode,
    required this.mirroring,
    required this.irqCounter,
    required this.irqLatch,
    required this.irqReload,
    required this.irqEnabled,
    required this.a12LowStart,
    super.id = 4,
  });

  factory MMC3State.fromByteData(ByteData data, int offset) {
    return MMC3State(
      register: data.getUint8(offset),
      r0: data.getUint8(offset + 1),
      r1: data.getUint8(offset + 2),
      r2: data.getUint8(offset + 3),
      r3: data.getUint8(offset + 4),
      r4: data.getUint8(offset + 5),
      r5: data.getUint8(offset + 6),
      r6: data.getUint8(offset + 7),
      r7: data.getUint8(offset + 8),
      prgBankMode: data.getUint8(offset + 9),
      chrBankMode: data.getUint8(offset + 10),
      mirroring: data.getUint8(offset + 11),
      irqCounter: data.getUint8(offset + 12),
      irqLatch: data.getUint8(offset + 13),
      irqReload: data.getUint8(offset + 14) == 1,
      irqEnabled: data.getUint8(offset + 15) == 1,
      a12LowStart: data.getUint64(offset + 16),
    );
  }

  final int register;
  final int r0;
  final int r1;
  final int r2;
  final int r3;
  final int r4;
  final int r5;
  final int r6;
  final int r7;

  final int prgBankMode;

  final int chrBankMode;

  final int mirroring;

  final int irqCounter;
  final int irqLatch;

  final bool irqReload;
  final bool irqEnabled;

  final int a12LowStart;

  @override
  int get byteLength => 24;

  @override
  void toByteData(ByteData data, int offset) {
    data
      ..setUint8(offset, register)
      ..setUint8(offset + 1, r0)
      ..setUint8(offset + 2, r1)
      ..setUint8(offset + 3, r2)
      ..setUint8(offset + 4, r3)
      ..setUint8(offset + 5, r4)
      ..setUint8(offset + 6, r5)
      ..setUint8(offset + 7, r6)
      ..setUint8(offset + 8, r7)
      ..setUint8(offset + 9, prgBankMode)
      ..setUint8(offset + 10, chrBankMode)
      ..setUint8(offset + 11, mirroring)
      ..setUint8(offset + 12, irqCounter)
      ..setUint8(offset + 13, irqLatch)
      ..setUint8(offset + 14, irqReload ? 1 : 0)
      ..setUint8(offset + 15, irqEnabled ? 1 : 0)
      ..setUint64(offset + 16, a12LowStart);
  }
}
