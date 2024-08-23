import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/mapper/axrom_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';

class AxROM extends Mapper {
  AxROM() : super(7);

  int prgBank = 0;

  int vramBank = 0;

  @override
  int prgBankSize = 0x8000;

  @override
  int chrBankSize = 0x2000;

  @override
  AXROMState get state => AXROMState(
        prgBank: prgBank,
        vramBank: vramBank,
      );

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
    prgBank = 0;
    vramBank = 0;

    _updateState();
  }

  @override
  void writePrg(int address, int value) {
    prgBank = value & 0x07;
    vramBank = value.bit(4);

    _updateState();
  }

  void _updateState() {
    _updatePrgPages();
    _updateMirroring();
  }

  void _updatePrgPages() {
    setPrgPage(0, prgBank);
  }

  void _updateMirroring() {
    if (vramBank == 0) {
      nametableLayout = NametableLayout.singleLower;
    } else {
      nametableLayout = NametableLayout.singleUpper;
    }
  }
}
