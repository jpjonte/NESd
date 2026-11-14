import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/mapper87_state.dart';

class Mapper87 extends Mapper {
  Mapper87() : super(87);

  @override
  String get name => 'J87';

  @override
  bool get hasFixedMirroring => true;

  @override
  int prgRomPageSize = 0x8000;

  @override
  int chrPageSize = 0x2000;

  int _chrBank = 0;

  @override
  Mapper87State get state => Mapper87State(chrBank: _chrBank);

  @override
  set state(covariant Mapper87State state) {
    _chrBank = state.chrBank;

    _updateState();
  }

  @override
  void reset() {
    super.reset();

    _chrBank = 0;

    _updateState();
  }

  @override
  void cpuWrite(int address, int value) {
    super.cpuWrite(address, value);

    if (address & 0xe000 != 0x6000) {
      return;
    }

    // The board wires D0 to CHR A14 and D1 to CHR A13.
    _chrBank = (value & 0x01) << 1 | (value & 0x02) >> 1;

    _updateChrPages();
  }

  void _updateState() {
    _updatePrgPages();
    _updateChrPages();
  }

  void _updatePrgPages() {
    mapCpu(0x8000, 0xffff, 0);
  }

  void _updateChrPages() {
    mapPpu(0x0000, 0x1fff, _chrBank);
  }
}
