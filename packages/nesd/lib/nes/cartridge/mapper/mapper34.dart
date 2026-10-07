import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/mapper34_state.dart';

class Mapper34 extends Mapper {
  Mapper34(super.id, [super.subMapperId]);

  @override
  String get name => switch ((id, _isNina001)) {
    (241, _) => 'BxROM (WRAM)',
    (_, true) => 'NINA-001',
    _ => 'BNROM',
  };

  @override
  bool get hasFixedMirroring => true;

  @override
  int prgRomPageSize = 0x8000;

  @override
  int chrPageSize = 0x1000;

  late final bool _isNina001 =
      id == 34 &&
      switch (subMapperId) {
        1 => true,
        2 => false,
        _ => cartridge.chrRom.length > 0x2000,
      };

  int _prgBank = 0;

  int _chrBank0 = 0;

  int _chrBank1 = 1;

  @override
  Mapper34State get state => Mapper34State(
    prgBank: _prgBank,
    chrBank0: _chrBank0,
    chrBank1: _chrBank1,
    id: id,
  );

  @override
  set state(covariant Mapper34State state) {
    _prgBank = state.prgBank;
    _chrBank0 = state.chrBank0;
    _chrBank1 = state.chrBank1;

    _updateState();
  }

  @override
  void reset() {
    super.reset();

    _prgBank = 0;
    _chrBank0 = 0;
    _chrBank1 = 1;

    _updateState();
  }

  @override
  void cpuWrite(int address, int value) {
    super.cpuWrite(address, value);

    if (_isNina001) {
      _ninaWrite(address, value);
    } else if (address >= 0x8000) {
      _prgBank = value;

      _updatePrgPages();
    }
  }

  void _ninaWrite(int address, int value) {
    switch (address) {
      case 0x7ffd:
        _prgBank = value;

        _updatePrgPages();
      case 0x7ffe:
        _chrBank0 = value;

        _updateChrPages();
      case 0x7fff:
        _chrBank1 = value;

        _updateChrPages();
    }
  }

  void _updateState() {
    _updatePrgPages();
    _updateChrPages();
  }

  void _updatePrgPages() {
    mapCpu(0x8000, 0xffff, _prgBank);
  }

  void _updateChrPages() {
    mapPpu(0x0000, 0x0fff, _chrBank0);
    mapPpu(0x1000, 0x1fff, _chrBank1);
  }
}
