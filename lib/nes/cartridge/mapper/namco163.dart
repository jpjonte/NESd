import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/namco163_state.dart';
import 'package:nesd/nes/cpu/irq_source.dart';

class Namco163 extends Mapper {
  Namco163() : super(19);

  @override
  String name = 'Namco 163';

  @override
  Namco163State get state => Namco163State(
    prgBank0: _prgBank0,
    prgBank1: _prgBank1,
    prgBank2: _prgBank2,
    prgRamWriteProtect: _prgRamWriteProtect,
    chrBanks: _chrBanks,
    disableNametables0: _disableNametables0,
    disableNametables1: _disableNametables1,
    irqCounter: _irqCounter,
    irqEnabled: _irqEnabled,
  );

  @override
  set state(covariant Namco163State state) {
    _prgBank0 = state.prgBank0;
    _prgBank1 = state.prgBank1;
    _prgBank2 = state.prgBank2;

    _prgRamWriteProtect.setRange(0, 4, state.prgRamWriteProtect);

    _chrBanks.setRange(0, 12, state.chrBanks);

    _disableNametables0 = state.disableNametables0;
    _disableNametables1 = state.disableNametables1;

    _irqCounter = state.irqCounter;
    _irqEnabled = state.irqEnabled;

    _updateState();
  }

  @override
  int prgRomPageSize = 0x2000;

  @override
  int get prgRamPageSize => 0x800;

  @override
  int chrPageSize = 0x400;

  int _prgBank0 = 0;
  int _prgBank1 = 0;
  int _prgBank2 = 0;

  final List<bool> _prgRamWriteProtect = List.filled(4, false);

  final List<int> _chrBanks = List.filled(12, 0);

  bool _disableNametables0 = false;
  bool _disableNametables1 = false;

  int _irqCounter = 0;
  bool _irqEnabled = false;

  @override
  void reset() {
    super.reset();

    _prgBank0 = 0;
    _prgBank1 = 0;
    _prgBank2 = 0;

    _prgRamWriteProtect.fillRange(0, 4, false);

    _chrBanks.fillRange(0, 12, 0);

    _disableNametables0 = false;
    _disableNametables1 = false;

    _irqCounter = 0;
    _irqEnabled = false;

    mapCpu(0x6000, 0xbfff, 0);
    mapCpu(0xe000, 0xffff, -1);

    mapPpu(0x0000, 0x1fff, 0);

    _updateState();
  }

  @override
  void step() {
    if (_irqCounter < 0x7fff) {
      _irqCounter++;

      if (_irqCounter == 0x7fff && _irqEnabled) {
        bus.triggerIrq(IrqSource.mapper);
      }
    }
  }

  @override
  int cpuRead(int address, {bool disableSideEffects = false}) {
    switch (address & 0xf800) {
      case 0x4800:
      // TODO sound RAM
      case 0x5000:
        return _irqCounter & 0xff;
      case 0x5800:
        return (_irqCounter >> 8).setBit(7, _irqEnabled ? 1 : 0);
    }

    return super.cpuRead(address, disableSideEffects: disableSideEffects);
  }

  @override
  void cpuWrite(int address, int value) {
    switch (address & 0xf800) {
      case 0x4800:
      // TODO sound RAM
      case 0x5000:
        _irqCounter = (_irqCounter & 0xff00) | value;

        bus.clearIrq(IrqSource.mapper);
      case 0x5800:
        _irqCounter = ((value & 0x7f) << 8) | (_irqCounter & 0x00ff);
        _irqEnabled = value.bit(7) == 1;

        bus.clearIrq(IrqSource.mapper);
      case 0x8000:
      case 0x8800:
      case 0x9000:
      case 0x9800:
      case 0xa000:
      case 0xa800:
      case 0xb000:
      case 0xb800:
      case 0xc000:
      case 0xc800:
      case 0xd000:
      case 0xd800:
        _chrBanks[(address - 0x8000) >> 11] = value;

        _updateChrBanks();
      case 0xe000:
        _prgBank0 = value & 0x3f;
        // bit 6: TODO sound disable

        _updatePrgBanks();
      case 0xe800:
        _prgBank1 = value & 0x3f;
        _disableNametables0 = value.bit(6) == 1;
        _disableNametables1 = value.bit(7) == 1;

        _updatePrgBanks();
      case 0xf000:
        _prgBank2 = value & 0x3f;

        _updatePrgBanks();

      case 0xf800:
        final enableWrites = (value >> 4) == 4;

        for (var i = 0; i < 4; i++) {
          _prgRamWriteProtect[i] = !enableWrites || value.bit(i) == 1;
        }

        _updatePrgRam();
    }

    super.cpuWrite(address, value);
  }

  void _updateState() {
    _updatePrgRam();
    _updatePrgBanks();
    _updateChrBanks();
  }

  void _updatePrgRam() {
    for (var i = 0; i < 4; i++) {
      mapCpu(
        0x6000 + (i * 0x0800),
        0x67ff + (i * 0x0800),
        i,
        type: CpuMemoryType.prgRam,
        access:
            _prgRamWriteProtect[i] ? MemoryAccess.read : MemoryAccess.readWrite,
      );
    }
  }

  void _updatePrgBanks() {
    mapCpu(0x8000, 0x9fff, _prgBank0);
    mapCpu(0xa000, 0xbfff, _prgBank1);
    mapCpu(0xc000, 0xdfff, _prgBank2);
  }

  void _updateChrBanks() {
    for (var bank = 0; bank < 12; bank++) {
      _mapPpu(
        0x0000 + (bank * 0x400),
        0x03ff + (bank * 0x400),
        _chrBanks[bank],
        enableNametables: switch (bank) {
          < 4 => !_disableNametables0,
          < 8 => !_disableNametables1,
          _ => true,
        },
      );
    }
  }

  void _mapPpu(
    int fromAddress,
    int toAddress,
    int page, {
    bool enableNametables = false,
  }) {
    final resolvedPage = switch (page) {
      < 0xe0 => page,
      _ => enableNametables ? (page & 1) : page,
    };

    final resolvedType = switch (page) {
      < 0xe0 => PpuMemoryType.chrRom,
      _ => enableNametables ? PpuMemoryType.nametable : PpuMemoryType.chrRom,
    };

    mapPpu(fromAddress, toAddress, resolvedPage, type: resolvedType);
  }
}
