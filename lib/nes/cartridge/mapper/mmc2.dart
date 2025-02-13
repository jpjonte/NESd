import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/mmc2_state.dart';

class MMC2 extends Mapper {
  MMC2() : super(9);

  @override
  String name = 'MMC2';

  @override
  int prgRomPageSize = 0x2000;

  @override
  int chrPageSize = 0x1000;

  int _prgBank = 0;

  final List<int> _chrBank0 = List.filled(2, 0);
  final List<int> _chrBank1 = List.filled(2, 0);

  int _chrLatch0 = 0;
  int _chrLatch1 = 0;

  int _mirroring = 0;

  bool _updateChr = false;

  @override
  MMC2State get state => MMC2State(
        prgBank: _prgBank,
        chrBank0: _chrBank0,
        chrBank1: _chrBank1,
        chrLatch0: _chrLatch0,
        chrLatch1: _chrLatch1,
        mirroring: _mirroring,
      );

  @override
  set state(covariant MMC2State state) {
    _prgBank = state.prgBank;

    _chrBank0[0] = state.chrBank0[0];
    _chrBank0[1] = state.chrBank0[1];

    _chrBank1[0] = state.chrBank1[0];
    _chrBank1[1] = state.chrBank1[1];

    _chrLatch0 = state.chrLatch0;
    _chrLatch1 = state.chrLatch1;

    _mirroring = state.mirroring;

    _updateState();
  }

  @override
  void reset() {
    super.reset();

    _prgBank = 0;

    _chrBank0[0] = 0;
    _chrBank0[1] = 0;

    _chrBank1[0] = 0;
    _chrBank1[1] = 0;

    _chrLatch0 = 0;
    _chrLatch1 = 0;

    _mirroring = 0;

    _updateChr = true;

    _updateState();
  }

  @override
  void updatePpuAddress(int address) {
    if (_updateChr) {
      _updateChr = false;
      _updateChrPages();
    }

    if (address == 0x0fd8) {
      _chrLatch0 = 0;
      _updateChr = true;
    } else if (address == 0x0fe8) {
      _chrLatch0 = 1;
      _updateChr = true;
    } else if (address >= 0x1fd8 && address <= 0x1fdf) {
      _chrLatch1 = 0;
      _updateChr = true;
    } else if (address >= 0x1fe8 && address <= 0x1fef) {
      _chrLatch1 = 1;
      _updateChr = true;
    }
  }

  @override
  void cpuWrite(int address, int value) {
    super.cpuWrite(address, value);

    switch (address & 0xf000) {
      case 0xa000:
        _prgBank = value & 0xf;
        _updatePrgPages();
      case 0xb000:
        _chrBank0[0] = value & 0x1f;
        _updateChrPages();
      case 0xc000:
        _chrBank0[1] = value & 0x1f;
        _updateChrPages();
      case 0xd000:
        _chrBank1[0] = value & 0x1f;
        _updateChrPages();
      case 0xe000:
        _chrBank1[1] = value & 0x1f;
        _updateChrPages();
      case 0xf000:
        _mirroring = value & 0x1;
        _updateMirroring();
    }
  }

  void _updateState() {
    _updatePrgPages();
    _updateChrPages();
    _updateMirroring();
  }

  void _updatePrgPages() {
    mapCpu(0x8000, 0x9fff, _prgBank);
    mapCpu(0xa000, 0xbfff, -3);
    mapCpu(0xc000, 0xdfff, -2);
    mapCpu(0xe000, 0xffff, -1);
  }

  void _updateChrPages() {
    mapPpu(0x0000, 0x0fff, _chrBank0[_chrLatch0]);
    mapPpu(0x1000, 0x1fff, _chrBank1[_chrLatch1]);
  }

  void _updateMirroring() {
    nametableLayout = switch (_mirroring) {
      0 => NametableLayout.horizontal,
      1 => NametableLayout.vertical,
      _ => NametableLayout.horizontal,
    };
  }
}
