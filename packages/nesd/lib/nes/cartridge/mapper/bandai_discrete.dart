import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/mapper/bandai_discrete_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';

class BandaiDiscrete extends Mapper {
  BandaiDiscrete(super.id);

  @override
  String name = 'Bandai discrete';

  @override
  int prgRomPageSize = 0x4000;

  @override
  int chrPageSize = 0x2000;

  int _prgBank = 0;

  int _chrBank = 0;

  int _nametable = 0;

  bool get _hasMirroringControl => id == 152;

  @override
  bool get hasFixedMirroring => !_hasMirroringControl;

  @override
  BandaiDiscreteState get state => BandaiDiscreteState(
    id: id,
    prgBank: _prgBank,
    chrBank: _chrBank,
    nametable: _nametable,
  );

  @override
  set state(covariant BandaiDiscreteState state) {
    _prgBank = state.prgBank;
    _chrBank = state.chrBank;
    _nametable = state.nametable;

    _updateState();
  }

  @override
  void reset() {
    super.reset();

    _prgBank = 0;
    _chrBank = 0;
    _nametable = 0;

    _updateState();
  }

  @override
  void cpuWrite(int address, int value) {
    super.cpuWrite(address, value);

    if (address < 0x8000) {
      return;
    }

    final latched = value & cpuRead(address, disableSideEffects: true);

    _prgBank = (latched >> 4) & (_hasMirroringControl ? 0x07 : 0x0f);
    _chrBank = latched & 0x0f;
    _nametable = latched.bit(7);

    _updateState();
  }

  void _updateState() {
    _updatePrgPages();
    _updateChrPages();
    _updateMirroring();
  }

  void _updatePrgPages() {
    mapCpu(0x8000, 0xbfff, _prgBank);
    mapCpu(0xc000, 0xffff, -1);
  }

  void _updateChrPages() {
    mapPpu(0x0000, 0x1fff, _chrBank);
  }

  void _updateMirroring() {
    if (!_hasMirroringControl) {
      return;
    }

    nametableLayout = _nametable == 0
        ? NametableLayout.singleLower
        : NametableLayout.singleUpper;
  }
}
