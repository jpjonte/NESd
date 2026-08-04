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

    super.cpuWrite(address, value);
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
}
