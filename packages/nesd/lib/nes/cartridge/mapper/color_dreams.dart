import 'package:nesd/nes/cartridge/mapper/color_dreams_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';

class ColorDreams extends Mapper {
  ColorDreams() : super(11);

  @override
  String name = 'Color Dreams';

  @override
  int prgRomPageSize = 0x8000;

  @override
  int chrPageSize = 0x2000;

  int _prgBank = 0;

  int _chrBank = 0;

  @override
  ColorDreamsState get state =>
      ColorDreamsState(prgBank: _prgBank, chrBank: _chrBank);

  @override
  set state(covariant ColorDreamsState state) {
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

    if (address < 0x8000) {
      return;
    }

    _prgBank = value & 0x03;
    _chrBank = (value >> 4) & 0x0f;

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
