import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/mmc1_state.dart';

class MMC1 extends Mapper {
  MMC1() : super(1);

  @override
  String name = 'MMC1';

  @override
  int prgRomPageSize = 0x4000;

  @override
  int chrPageSize = 0x1000;

  int _shift = 0x10;

  int _control = 0x0c;

  int get _controlMirroring => _control & 0x3;
  int get _controlPrgMode => (_control >> 2) & 0x3;
  int get _controlChrMode => _control.bit(4);

  int _chrBank0 = 0;
  int _chrBank1 = 1;

  int _prgBank = 0;

  int get _prgBankValue => _prgBank & 0xf;

  @override
  MMC1State get state => MMC1State(
        shift: _shift,
        control: _control,
        chrBank0: _chrBank0,
        chrBank1: _chrBank1,
        prgBank: _prgBank,
      );

  @override
  set state(covariant MMC1State state) {
    _shift = state.shift;
    _control = state.control;
    _chrBank0 = state.chrBank0;
    _chrBank1 = state.chrBank1;
    _prgBank = state.prgBank;

    _updateState();
  }

  @override
  void reset() {
    super.reset();

    final mirroring = switch (cartridge.nametableLayout) {
      NametableLayout.vertical => 3,
      NametableLayout.horizontal => 2,
      NametableLayout.four => 0,
      NametableLayout.singleUpper => 0,
      NametableLayout.singleLower => 0,
    };

    _shift = 0x10;
    _control = 0x0c | mirroring;
    _chrBank0 = 0;
    _chrBank1 = 1;
    _prgBank = 0;

    _updateState();
  }

  @override
  void cpuWrite(int address, int value) {
    super.cpuWrite(address, value);

    if (address < 0x8000) {
      return;
    }

    // TODO ignore consecutive cycle writes
    if (value.bit(7) == 1) {
      _shift = 0x10;
      _control = _control | 0xc;

      _updateState();

      return;
    }

    if (_shift.bit(0) == 1) {
      final register = (address >> 13) & 0x3;
      final registerValue = value.bit(0) << 4 | ((_shift >> 1) & 0xf);

      _shift = 0x10;

      switch (register) {
        case 0:
          _control = registerValue;
          _updateState();
        case 1:
          _chrBank0 = registerValue;
          _updateChrPages();
        case 2:
          _chrBank1 = registerValue;
          _updateChrPages();
        case 3:
          _prgBank = registerValue;
          _updatePrgPages();
      }

      return;
    }

    _shift >>= 1;
    _shift = _shift.setBit(4, value.bit(0));
  }

  void _updateState() {
    _updatePrgPages();
    _updateChrPages();
    _updateMirroring();
  }

  void _updatePrgPages() {
    switch (_controlPrgMode) {
      case 0: // switchable 32k bank
      case 1:
        mapCpu(0x8000, 0xbfff, _prgBankValue & 0xe);
        mapCpu(0xc000, 0xffff, _prgBankValue | 0x1);
      case 2:
        // fixed first bank at 0x8000
        mapCpu(0x8000, 0xbfff, 0);
        // switchable 16k bank at 0xc000
        mapCpu(0xc000, 0xffff, _prgBankValue & 0xf);
      case 3:
        // switchable 16k bank at 0x8000
        mapCpu(0x8000, 0xbfff, _prgBankValue & 0xf);
        // fixed last bank at 0xc000
        mapCpu(0xc000, 0xffff, -1);
    }
  }

  void _updateChrPages() {
    switch (_controlChrMode) {
      case 0:
        mapPpu(0x0000, 0x0fff, _chrBank0 & 0x1e);
        mapPpu(0x1000, 0x1fff, _chrBank0 | 1);
      case 1:
        mapPpu(0x0000, 0x0fff, _chrBank0);
        mapPpu(0x1000, 0x1fff, _chrBank1);
    }
  }

  void _updateMirroring() {
    nametableLayout = switch (_controlMirroring) {
      0 => NametableLayout.singleLower,
      1 => NametableLayout.singleUpper,
      2 => NametableLayout.horizontal,
      3 => NametableLayout.vertical,
      _ => NametableLayout.horizontal,
    };
  }
}
