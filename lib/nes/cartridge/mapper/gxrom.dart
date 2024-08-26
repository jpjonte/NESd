import 'package:nesd/nes/cartridge/mapper/gxrom_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';

class GxROM extends Mapper {
  GxROM() : super(66);

  @override
  String name = 'GxROM';

  @override
  int prgBankSize = 0x8000;

  @override
  int chrBankSize = 0x2000;

  int _prgBank = 0;

  int _chrBank = 0;

  @override
  GxROMState get state => GxROMState(
        prgBank: _prgBank,
        chrBank: _chrBank,
      );

  @override
  set state(covariant GxROMState state) {
    _prgBank = state.prgBank;
    _chrBank = state.chrBank;

    _updateState();
  }

  @override
  void reset() {
    _prgBank = 0;
    _chrBank = 0;

    _updateState();
  }

  @override
  void writePrg(int address, int value) {
    _chrBank = value & 0x03;
    _prgBank = (value >> 4) & 0x03;

    _updateState();
  }

  void _updateState() {
    _updatePrgPages();
    _updateChrPages();
  }

  void _updatePrgPages() {
    setPrgPage(0, _prgBank);
  }

  void _updateChrPages() {
    setChrPage(0, _chrBank);
  }
}
