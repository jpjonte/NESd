import 'package:nesd/nes/cartridge/mapper/cnrom_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';

class CNROM extends Mapper {
  CNROM() : super(3);

  int chrBank = 0;

  @override
  int prgBankSize = 0x8000;

  @override
  int chrBankSize = 0x2000;

  @override
  CNROMState get state => CNROMState(chrBank: chrBank);

  @override
  set state(covariant CNROMState state) {
    chrBank = state.chrBank;

    _updateChrPages();
  }

  @override
  String name = 'CNROM';

  @override
  void reset() {
    chrBank = 0;

    _updateChrPages();
  }

  @override
  void writePrg(int address, int value) {
    chrBank = value & 0x0f;

    _updateChrPages();
  }

  void _updateChrPages() {
    setChrPage(0, chrBank);
  }
}
