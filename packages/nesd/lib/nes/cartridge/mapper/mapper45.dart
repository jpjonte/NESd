import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/cartridge/mapper/mapper45_state.dart';
import 'package:nesd/nes/cartridge/mapper/mmc3.dart';

class Mapper45 extends MMC3 {
  Mapper45([int subMapperId = 0]) : super(45, subMapperId);

  @override
  String get name => 'GA23C';

  final List<int> outerRegisters = List.filled(4, 0);

  int writeIndex = 0;

  int get prgAnd => 0x3f ^ (outerRegisters[3] & 0x3f);

  int get prgOr => outerRegisters[1] | ((outerRegisters[2] & 0xc0) << 2);

  int get chrAnd => 0xff >> (0x0f - (outerRegisters[2] & 0x0f));

  int get chrOr => outerRegisters[0] | ((outerRegisters[2] & 0xf0) << 4);

  bool get locked => outerRegisters[3].bit(6) == 1;

  @override
  Mapper45State get state {
    final mmc3 = super.state;

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
      outer0: outerRegisters[0],
      outer1: outerRegisters[1],
      outer2: outerRegisters[2],
      outer3: outerRegisters[3],
      writeIndex: writeIndex,
    );
  }

  @override
  set state(covariant Mapper45State state) {
    outerRegisters
      ..[0] = state.outer0
      ..[1] = state.outer1
      ..[2] = state.outer2
      ..[3] = state.outer3;

    writeIndex = state.writeIndex;

    super.state = state;
  }

  @override
  void reset() {
    outerRegisters.fillRange(0, outerRegisters.length, 0);
    writeIndex = 0;

    super.reset();
  }

  @override
  void cpuWrite(int address, int value) {
    super.cpuWrite(address, value);

    switch (address & 0xf001) {
      case 0x6000:
        _writeOuter(value);
      case 0x6001:
        _resetOuterRegisters();
    }
  }

  void _writeOuter(int value) {
    if (locked) {
      return;
    }

    outerRegisters[writeIndex] = value;
    writeIndex = (writeIndex + 1) & 0x3;

    _remapBanks();
  }

  void _resetOuterRegisters() {
    outerRegisters.fillRange(0, outerRegisters.length, 0);
    writeIndex = 0;

    _remapBanks();
  }

  void _remapBanks() {
    updatePrgPages();
    updateChrPages();
  }

  @override
  int prgPage(int slot) => (super.prgPage(slot) & prgAnd) | prgOr;

  @override
  int chrPage(int slot) {
    final page = super.chrPage(slot);

    if (cartridge.chrRam.isNotEmpty) {
      return page;
    }

    return (page & chrAnd) | chrOr;
  }
}
