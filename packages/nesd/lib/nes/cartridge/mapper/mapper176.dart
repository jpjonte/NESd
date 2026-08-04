import 'package:nesd/exception/unsupported_mapper.dart';
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

  @override
  int get registerAddressMask => 0xe003;

  @override
  int bankWriteMask(int register) {
    final eightBitPrg = subMapperId == 1 || subMapperId == 3;

    return switch (register) {
      0 || 1 => 0xfe,
      6 || 7 => eightBitPrg ? 0xff : 0x3f,
      _ => 0xff,
    };
  }

  int get outerAddressMask =>
      (subMapperId == 3 ? 0xf007 : 0xf003) | (0x10 << solderPad);

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
    if ((mode & 0x7) == 5) {
      unromLatch = value;

      updatePrgPages();
    }
  }

  void _writeOuter(int address, int value) {
    if (subMapperId == 5 && (address & 0xf800) == 0x4800) {
      prgBaseMsb = value & 0x3f;

      _remapAll();

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

    _remapAll();
  }

  void _remapAll() {
    updatePrgPages();
    updateChrPages();
  }

  int get prgBase {
    final lsb = switch (subMapperId) {
      5 => prgBaseLsb & 0x1f,
      _ => prgBaseLsb & 0x7f,
    };

    return lsb << 1;
  }

  int get prgMmc3Bits => switch (mode & 0x7) {
    1 => 5,
    2 => 4,
    _ => subMapperId == 1 || subMapperId == 3 ? 8 : 6,
  };

  @override
  int prgPage(int slot) => switch (mode & 0x7) {
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

  int _mmc3PrgPage(int slot) {
    final bits = prgMmc3Bits;
    final mask = (1 << bits) - 1;

    final inner = switch (prgBankMode) {
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
}
