import 'package:nesd/exception/unsupported_mapper.dart';
import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/mapper176_state.dart';
import 'package:nesd/nes/cartridge/mapper/mmc3.dart';

class Mapper176 extends MMC3 {
  Mapper176(int subMapperId, {this.solderPad = 0}) : super(176, subMapperId) {
    if (subMapperId == 2 || subMapperId > 5) {
      throw UnsupportedMapper(176, subMapperId);
    }
  }

  @override
  String get name => 'Mapper 176';

  final int solderPad;

  int mode = 0;
  int prgBaseLsb = 0;
  int prgBaseMsb = 0;
  int chrBaseLsb = 0;
  int chrBaseMsb = 0;
  int extendedRegister = 0;

  int unromLatch = 0;
  int cnromLatch = 0;

  /// Slot order for the 1 KiB CHR banks in extended MMC3 mode.
  static const _extendedChrOrder = [0, 0xa, 1, 0xb, 2, 3, 4, 5];

  /// PRG window order in extended mode: register per slot ($8000, $A000,
  /// $C000, $E000) when `prgBankMode` is 0.
  static const _extendedPrgOrder = [6, 7, 8, 9];

  /// PRG window order in extended mode when `prgBankMode` is 1: registers
  /// 6 and 8 trade places, which swaps the $8000 and $C000 windows.
  static const _extendedPrgOrderSwapped = [8, 7, 6, 9];

  /// Extended MMC3 mode, enabled by $5xx3 bit 1 on submapper 1.
  bool get extendedMode => subMapperId == 1 && extendedRegister.bit(1) == 1;

  @override
  int get registerAddressMask => 0xe003;

  @override
  int get bankSelectMask => extendedMode ? 0x0f : 0x07;

  @override
  bool isPrgBankRegister(int register) =>
      extendedMode ? register >= 6 && register <= 9 : register >= 6;

  @override
  int get minChrRamSize => subMapperId <= 1 ? 0x2000 : 0;

  @override
  PpuMemoryType get chrMemoryType {
    if (subMapperId > 1 || (subMapperId == 1 && chrFromPpu)) {
      return PpuMemoryType.chrRom;
    }

    return mode.bit(5) == 1 ? PpuMemoryType.chrRam : PpuMemoryType.chrRom;
  }

  @override
  int bankWriteMask(int register) {
    final eightBitPrg = subMapperId == 1 || subMapperId == 3;

    return switch (register) {
      // In extended mode these are 1 KiB banks, not 2 KiB pairs.
      0 || 1 => extendedMode ? 0xff : 0xfe,
      6 || 7 => eightBitPrg ? 0xff : 0x3f,
      _ => 0xff,
    };
  }

  int get outerAddressMask =>
      (subMapperId == 3 ? 0xf007 : 0xf003) | (0x10 << solderPad);

  @override
  Mapper176State get state {
    final mmc3 = super.state;

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
      bank8: banks[8],
      bank9: banks[9],
      bank10: banks[10],
      bank11: banks[11],
      mode: mode,
      prgBaseLsb: prgBaseLsb,
      prgBaseMsb: prgBaseMsb,
      chrBaseLsb: chrBaseLsb,
      chrBaseMsb: chrBaseMsb,
      extendedRegister: extendedRegister,
      unromLatch: unromLatch,
      cnromLatch: cnromLatch,
      solderPad: solderPad,
    );
  }

  @override
  set state(covariant Mapper176State state) {
    banks
      ..[8] = state.bank8
      ..[9] = state.bank9
      ..[10] = state.bank10
      ..[11] = state.bank11;

    mode = state.mode;
    prgBaseLsb = state.prgBaseLsb;
    prgBaseMsb = state.prgBaseMsb;
    chrBaseLsb = state.chrBaseLsb;
    chrBaseMsb = state.chrBaseMsb;
    extendedRegister = state.extendedRegister;
    unromLatch = state.unromLatch;
    cnromLatch = state.cnromLatch;

    super.state = state;
  }

  @override
  void reset() {
    mode = 0;
    prgBaseLsb = 0;
    prgBaseMsb = 0;
    chrBaseLsb = 0;
    chrBaseMsb = 0;
    extendedRegister = 0;
    unromLatch = 0;
    cnromLatch = 0;

    super.reset();

    banks
      ..[0] = 0x00
      ..[1] = 0x02
      ..[2] = 0x04
      ..[3] = 0x05
      ..[4] = 0x06
      ..[5] = 0x07
      ..[6] = 0x00
      ..[7] = 0x01
      ..[8] = 0xfe
      ..[9] = 0xff
      ..[10] = 0xff
      ..[11] = 0xff;

    updatePrgPages();
    updateChrPages();
  }

  @override
  void cpuWrite(int address, int value) {
    if (address >= 0x4020 && address < 0x6000) {
      _writeOuter(address, value);

      return;
    }

    if (address >= 0x8000) {
      _writeLatches(value);
    }

    super.cpuWrite(address, value);
  }

  void _writeLatches(int value) {
    if (!extendedMode && (mode & 0x7) == 5) {
      unromLatch = value;

      updatePrgPages();
    }

    if (cnromMode) {
      cnromLatch = value;

      updateChrPages();
    }
  }

  void _writeOuter(int address, int value) {
    if (subMapperId == 5 && (address & 0xf800) == 0x4800) {
      prgBaseMsb = value & 0x3f;

      _remapBanks();

      return;
    }

    final decoded = address & outerAddressMask;

    if ((decoded & ~0x7) != (0x5000 | (0x10 << solderPad))) {
      return;
    }

    switch (decoded & 0x7) {
      case 0:
        mode = value;
      case 1:
        prgBaseLsb = value & 0x7f;
      case 2:
        chrBaseLsb = value;
      case 3:
        extendedRegister = value;
      case 5:
        if (subMapperId == 3) {
          prgBaseMsb = value & 0xf;
        }
      case 6:
        if (subMapperId == 3) {
          chrBaseMsb = value & 0xf;
        }
    }

    _remapBanks();
  }

  void _remapBanks() {
    updatePrgPages();
    updateChrPages();
  }

  int get prgBase {
    final lsb = switch (subMapperId) {
      5 => prgBaseLsb & 0x1f,
      _ => prgBaseLsb & 0x7f,
    };

    final msb = switch (subMapperId) {
      3 => (prgBaseMsb & 0xf) << 8,
      4 => chrBaseLsb.bit(7) << 8,
      5 => (prgBaseMsb & 0x3f) << 6,
      _ => 0,
    };

    return (lsb << 1) | msb;
  }

  int get prgMmc3Bits {
    if (extendedMode) {
      return 8;
    }

    return switch (mode & 0x7) {
      1 => 5,
      2 => 4,
      _ => subMapperId == 1 || subMapperId == 3 ? 8 : 6,
    };
  }

  @override
  int prgPage(int slot) {
    if (extendedMode) {
      return _mmc3PrgPage(slot);
    }

    return switch (mode & 0x7) {
      // NROM-128: 16 KiB mirrored across $8000-$FFFF.
      3 => (prgBase & ~0x1) | (slot & 0x1),
      // NROM-256: 32 KiB at $8000-$FFFF.
      4 => (prgBase & ~0x3) | slot,
      // UNROM: latched 16 KiB at $8000, inner bank 7 at $C000.
      5 =>
        (prgBase & ~0xf) |
            ((slot < 2 ? unromLatch & 0x7 : 0x7) << 1) |
            (slot & 0x1),
      _ => _mmc3PrgPage(slot),
    };
  }

  int _mmc3PrgPage(int slot) {
    final bits = prgMmc3Bits;
    final mask = (1 << bits) - 1;

    final inner = extendedMode
        ? switch (prgBankMode) {
            0 => banks[_extendedPrgOrder[slot]],
            _ => banks[_extendedPrgOrderSwapped[slot]],
          }
        : switch (prgBankMode) {
            0 => switch (slot) {
              0 => banks[6],
              1 => banks[7],
              2 => mask - 1,
              _ => mask,
            },
            _ => switch (slot) {
              0 => mask - 1,
              1 => banks[7],
              2 => banks[6],
              _ => mask,
            },
          };

    return (prgBase & ~mask) | (inner & mask);
  }

  int get chrBase {
    final msb = subMapperId == 3 ? (chrBaseMsb & 0xf) << 11 : 0;

    return (chrBaseLsb << 3) | msb;
  }

  bool get chrFromPpu => mode.bit(6) == 1;

  bool get chrSmallOuterBank => mode.bit(4) == 1;

  bool get cnromMode => subMapperId == 1 && chrFromPpu && mode.bit(5) == 0;

  @override
  int chrPage(int slot) {
    if (!chrFromPpu) {
      final bits = chrSmallOuterBank ? 7 : 8;
      final mask = (1 << bits) - 1;

      return (chrBase & ~mask) | (_innerChrPage(slot) & mask);
    }

    if (cnromMode) {
      final latchBits = chrSmallOuterBank ? 1 : 2;
      final latchMask = (1 << latchBits) - 1;
      final baseMask = ~(((1 << latchBits) - 1) << 3 | 0x7);

      return (chrBase & baseMask) | ((cnromLatch & latchMask) << 3) | slot;
    }

    return (chrBase & ~0x7) | slot;
  }

  int _innerChrPage(int slot) {
    if (!extendedMode) {
      return super.chrPage(slot);
    }

    final index = chrBankMode == 0 ? slot : (slot + 4) & 0x7;

    return banks[_extendedChrOrder[index]];
  }
}
