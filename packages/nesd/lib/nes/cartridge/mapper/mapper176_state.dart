import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mmc3_state.dart';

class Mapper176State extends MMC3State {
  const Mapper176State({
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
    required this.bank8,
    required this.bank9,
    required this.bank10,
    required this.bank11,
    required this.mode,
    required this.prgBaseLsb,
    required this.prgBaseMsb,
    required this.chrBaseLsb,
    required this.chrBaseMsb,
    required this.extendedRegister,
    required this.unromLatch,
    required this.cnromLatch,
    required this.solderPad,
  }) : super(id: 176);

  factory Mapper176State.deserialize(PayloadReader reader) {
    final mmc3 = MMC3State.deserialize(reader);

    final version = reader.get(uint8);

    if (version != 0) {
      throw InvalidSerializationVersion('Mapper176', version);
    }

    return Mapper176State(
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
      bank8: reader.get(uint8),
      bank9: reader.get(uint8),
      bank10: reader.get(uint8),
      bank11: reader.get(uint8),
      mode: reader.get(uint8),
      prgBaseLsb: reader.get(uint8),
      prgBaseMsb: reader.get(uint8),
      chrBaseLsb: reader.get(uint8),
      chrBaseMsb: reader.get(uint8),
      extendedRegister: reader.get(uint8),
      unromLatch: reader.get(uint8),
      cnromLatch: reader.get(uint8),
      solderPad: reader.get(uint8),
    );
  }

  final int bank8;
  final int bank9;
  final int bank10;
  final int bank11;

  final int mode;
  final int prgBaseLsb;
  final int prgBaseMsb;
  final int chrBaseLsb;
  final int chrBaseMsb;
  final int extendedRegister;

  final int unromLatch;
  final int cnromLatch;

  final int solderPad;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(uint8, bank8)
      ..set(uint8, bank9)
      ..set(uint8, bank10)
      ..set(uint8, bank11)
      ..set(uint8, mode)
      ..set(uint8, prgBaseLsb)
      ..set(uint8, prgBaseMsb)
      ..set(uint8, chrBaseLsb)
      ..set(uint8, chrBaseMsb)
      ..set(uint8, extendedRegister)
      ..set(uint8, unromLatch)
      ..set(uint8, cnromLatch)
      ..set(uint8, solderPad);
  }
}
