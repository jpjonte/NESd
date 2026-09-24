import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/nina003006_state.dart';

class NINA003006 extends Mapper {
  NINA003006(super.id);

  @override
  String get name => id == 146 ? 'Sachen 3015' : 'NINA-003-006';

  @override
  int prgRomPageSize = 0x8000;

  @override
  int chrPageSize = 0x2000;

  int _prgBank = 0;

  int _chrBank = 0;

  @override
  NINA003006State get state =>
      NINA003006State(prgBank: _prgBank, chrBank: _chrBank, id: id);

  @override
  set state(covariant NINA003006State state) {
    _prgBank = state.prgBank;
    _chrBank = state.chrBank;

    _updateState();
  }

  @override
  void reset() {
    super.reset();

    _prgBank = 0;
    _chrBank = 0;

    _updateState();
  }

  @override
  void cpuWrite(int address, int value) {
    super.cpuWrite(address, value);

    if (address & 0xe100 != 0x4100) {
      return;
    }

    _prgBank = (value >> 3) & 0x01;
    _chrBank = value & 0x07;

    _updateState();
  }

  void _updateState() {
    _updatePrgPages();
    _updateChrPages();
  }

  void _updatePrgPages() {
    mapCpu(0x8000, 0xffff, _prgBank);
  }

  void _updateChrPages() {
    mapPpu(0x0000, 0x1fff, _chrBank);
  }
}
