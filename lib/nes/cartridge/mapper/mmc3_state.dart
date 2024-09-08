import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
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

  factory MMC3State.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => MMC3State._version0(reader),
      _ => throw InvalidSerializationVersion('MMC3', version),
    };
  }

  factory MMC3State._version0(PayloadReader reader) {
    return MMC3State(
      register: reader.get(uint8),
      r0: reader.get(uint8),
      r1: reader.get(uint8),
      r2: reader.get(uint8),
      r3: reader.get(uint8),
      r4: reader.get(uint8),
      r5: reader.get(uint8),
      r6: reader.get(uint8),
      r7: reader.get(uint8),
      prgBankMode: reader.get(uint8),
      chrBankMode: reader.get(uint8),
      mirroring: reader.get(uint8),
      irqCounter: reader.get(uint8),
      irqLatch: reader.get(uint8),
      irqReload: reader.get(boolean),
      irqEnabled: reader.get(boolean),
      a12LowStart: reader.get(uint64),
    );
  }

  factory MMC3State.legacyFromByteData(ByteData data, int offset) {
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
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(uint8, register)
      ..set(uint8, r0)
      ..set(uint8, r1)
      ..set(uint8, r2)
      ..set(uint8, r3)
      ..set(uint8, r4)
      ..set(uint8, r5)
      ..set(uint8, r6)
      ..set(uint8, r7)
      ..set(uint8, prgBankMode)
      ..set(uint8, chrBankMode)
      ..set(uint8, mirroring)
      ..set(uint8, irqCounter)
      ..set(uint8, irqLatch)
      ..set(boolean, irqReload)
      ..set(boolean, irqEnabled)
      ..set(uint64, a12LowStart);
  }
}
