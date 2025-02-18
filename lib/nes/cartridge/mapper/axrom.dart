import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/mapper/axrom_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';

class AxROM extends Mapper {
  AxROM() : super(7);

  int prgBank = 0;

  int vramBank = 0;

  @override
  int prgRomPageSize = 0x8000;

  @override
  int chrPageSize = 0x2000;

  @override
  AXROMState get state => AXROMState(prgBank: prgBank, vramBank: vramBank);

  @override
  set state(covariant AXROMState state) {
    prgBank = state.prgBank;
    vramBank = state.vramBank;

    _updateState();
  }

  @override
  String name = 'AxROM';

  @override
  void reset() {
    super.reset();

    prgBank = 0;
    vramBank = 0;

    _updateState();
  }

  @override
  void cpuWrite(int address, int value) {
    super.cpuWrite(address, value);

    if (address < 0x8000) {
      return;
    }

    prgBank = value & 0x07;
    vramBank = value.bit(4);

    _updateState();
  }

  void _updateState() {
    _updatePrgPages();
    _updateMirroring();
  }

  void _updatePrgPages() {
    mapCpu(0x8000, 0xffff, prgBank);
  }

  void _updateMirroring() {
    if (vramBank == 0) {
      nametableLayout = NametableLayout.singleLower;
    } else {
      nametableLayout = NametableLayout.singleUpper;
    }
  }
}
