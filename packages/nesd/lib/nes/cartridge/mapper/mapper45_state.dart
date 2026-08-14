import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mmc3_state.dart';

class Mapper45State extends MMC3State {
  const Mapper45State({
    required super.register,
    required super.r0,
    required super.r1,
    required super.r2,
    required super.r3,
    required super.r4,
    required super.r5,
    required super.r6,
    required super.r7,
    required super.prgBankMode,
    required super.chrBankMode,
    required super.mirroring,
    required super.irqCounter,
    required super.irqLatch,
    required super.irqReload,
    required super.irqEnabled,
    required super.a12LowStart,
    required this.outer0,
    required this.outer1,
    required this.outer2,
    required this.outer3,
    required this.writeIndex,
  }) : super(id: 45);

  factory Mapper45State.deserialize(PayloadReader reader) {
    final mmc3 = MMC3State.deserialize(reader);

    final version = reader.get(uint8);

    if (version != 0) {
      throw InvalidSerializationVersion('Mapper45', version);
    }

    return Mapper45State(
      register: mmc3.register,
      r0: mmc3.r0,
      r1: mmc3.r1,
      r2: mmc3.r2,
      r3: mmc3.r3,
      r4: mmc3.r4,
      r5: mmc3.r5,
      r6: mmc3.r6,
      r7: mmc3.r7,
      prgBankMode: mmc3.prgBankMode,
      chrBankMode: mmc3.chrBankMode,
      mirroring: mmc3.mirroring,
      irqCounter: mmc3.irqCounter,
      irqLatch: mmc3.irqLatch,
      irqReload: mmc3.irqReload,
      irqEnabled: mmc3.irqEnabled,
      a12LowStart: mmc3.a12LowStart,
      outer0: reader.get(uint8),
      outer1: reader.get(uint8),
      outer2: reader.get(uint8),
      outer3: reader.get(uint8),
      writeIndex: reader.get(uint8),
    );
  }

  final int outer0;
  final int outer1;
  final int outer2;
  final int outer3;

  final int writeIndex;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(uint8, outer0)
      ..set(uint8, outer1)
      ..set(uint8, outer2)
      ..set(uint8, outer3)
      ..set(uint8, writeIndex);
  }
}
