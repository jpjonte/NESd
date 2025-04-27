import 'dart:typed_data';

import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/mmc5_state.dart';
import 'package:nesd/nes/cpu/irq_source.dart';

enum SplitSide { left, right }

class MMC5 extends Mapper {
  MMC5() : super(5);

  @override
  String name = 'MMC5';

  @override
  int prgRomPageSize = 0x2000;

  @override
  int get chrPageSize => 0x400;

  int _prgBankMode = 0;
  int _prgRamProtect1 = 0;
  int _prgRamProtect2 = 0;

  final List<int> _prgRegisters = List.filled(5, 0);

  final List<int> _chrRegisters = List.filled(12, 0);

  final Uint8List _exram = Uint8List(0x400);

  final Uint8List _emptyNametable = Uint8List(0x400);

  final Uint8List _filledNametable = Uint8List(0x400);

  int _lastChrAddress = 0;

  int _chrBankMode = 0;
  int _chrPageHigh = 0;

  int _nametables = 0;

  int _fillModeTile = 0;
  int _fillModeColor = 0;

  int _lastPpuAddress = 0;

  int _ppuIdleCountdown = 0;
  bool _ppuInFrame = false;
  int _ppuNtReadCount = 0;
  int _scanline = 0;

  int _irqTargetScanline = 0;
  bool _irqEnabled = false;
  bool _irqPending = false;

  int _multiplicand = 0xff;
  int _multiplier = 0xff;

  int _tileCounter = 0;

  bool _lastExtraChr = false;

  bool _splitEnabled = false;
  bool _splitActive = false;
  SplitSide _splitSide = SplitSide.left;
  int _splitTile = 0;
  int _splitTileAddress = 0;
  int _splitScroll = 0;
  int _splitBank = 0;

  int _extendedRamMode = 0;
  int _extendedAttributeOffset = 0;
  int _extendedAttributeFetchCountdown = 0;
  int _extendedAttributeChrBank = 0;

  @override
  MMC5State get state => MMC5State(
    prgBankMode: _prgBankMode,
    prgRamProtect1: _prgRamProtect1,
    prgRamProtect2: _prgRamProtect2,
    prgRegisters: _prgRegisters,
    chrRegisters: _chrRegisters,
    exram: _exram,
    filledNametable: _filledNametable,
    chrBankMode: _chrBankMode,
    lastChrAddress: _lastChrAddress,
    chrPageHigh: _chrPageHigh,
    nametables: _nametables,
    fillModeTile: _fillModeTile,
    fillModeColor: _fillModeColor,
    lastPpuAddress: _lastPpuAddress,
    ppuIdleCountdown: _ppuIdleCountdown,
    ppuInFrame: _ppuInFrame,
    ppuNtReadCount: _ppuNtReadCount,
    scanline: _scanline,
    irqTargetScanline: _irqTargetScanline,
    irqEnabled: _irqEnabled,
    irqPending: _irqPending,
    multiplicand: _multiplicand,
    multiplier: _multiplier,
    tileCounter: _tileCounter,
    lastExtraChr: _lastExtraChr,
    splitEnabled: _splitEnabled,
    splitActive: _splitActive,
    splitSide: _splitSide,
    splitTile: _splitTile,
    splitTileAddress: _splitTileAddress,
    splitScroll: _splitScroll,
    splitBank: _splitBank,
    extendedRamMode: _extendedRamMode,
    extendedAttributeOffset: _extendedAttributeOffset,
    extendedAttributeFetchCountdown: _extendedAttributeFetchCountdown,
    extendedAttributeChrBank: _extendedAttributeChrBank,
  );

  @override
  set state(covariant MMC5State state) {
    _prgBankMode = state.prgBankMode;
    _chrBankMode = state.chrBankMode;

    _updateState();
  }

  @override
  void reset() {
    super.reset();

    _prgBankMode = 3;
    _prgRegisters[4] = 0xff;
    _prgRamProtect1 = 0;
    _prgRamProtect2 = 0;

    _nametables = 0;

    _fillModeTile = 0;
    _fillModeColor = 0;

    _chrBankMode = 0;
    _chrPageHigh = 0;

    _lastChrAddress = 0;
    _lastPpuAddress = 0;

    _ppuIdleCountdown = 0;
    _ppuInFrame = false;
    _ppuNtReadCount = 0;
    _scanline = 0;

    _irqTargetScanline = 0;
    _irqEnabled = false;
    _irqPending = false;

    _multiplicand = 0xff;
    _multiplier = 0xff;

    _tileCounter = 0;

    _lastExtraChr = false;

    _splitEnabled = false;
    _splitActive = false;
    _splitSide = SplitSide.left;
    _splitTile = 0;
    _splitTileAddress = 0;
    _splitScroll = 0;
    _splitBank = 0;

    _extendedRamMode = 0;
    _extendedAttributeOffset = 0;
    _extendedAttributeFetchCountdown = 0;
    _extendedAttributeChrBank = 0;

    _updateState();
  }

  @override
  void step() {
    if (_ppuIdleCountdown > 0) {
      _ppuIdleCountdown--;

      if (_ppuIdleCountdown == 0) {
        _ppuInFrame = false;

        _updateChrMapping();
      }
    }
  }

  @override
  int ppuRead(int address, {bool disableSideEffects = false}) {
    if (disableSideEffects) {
      return super.ppuRead(address, disableSideEffects: true);
    }

    final fetchingNametable =
        address >= 0x2000 && address <= 0x2fff && (address & 0x3ff) < 0x3c0;

    if (fetchingNametable) {
      _handleTileCounter();
    }

    _handleNtReadCounter(address);

    _ppuIdleCountdown = 3;
    _lastPpuAddress = address;

    if (_extendedRamMode <= 1 && _ppuInFrame) {
      if (_splitEnabled) {
        return _ppuReadSplitMode(address, fetchingNametable);
      }

      if (_extendedRamMode == 1 && (_tileCounter < 32 || _tileCounter >= 40)) {
        return _ppuReadExtendedAttributes(address, fetchingNametable);
      }
    }

    return super.ppuRead(address);
  }

  void _handleTileCounter() {
    final previous = _tileCounter;

    _tileCounter++;
    _splitActive = false;

    if (_ppuInFrame &&
        ((previous < 32 && _tileCounter >= 32) ||
            (previous < 40 && _tileCounter >= 40))) {
      _updateChrMapping();
    }
  }

  void _handleNtReadCounter(int address) {
    if (_ppuNtReadCount >= 2) {
      if (_ppuInFrame) {
        _scanline++;

        if (_scanline == _irqTargetScanline) {
          _irqPending = true;

          if (_irqEnabled) {
            bus.triggerIrq(IrqSource.mapper);
          }
        }
      } else {
        _ppuInFrame = true;
        _scanline = 0;

        _updateChrMapping();
      }

      _tileCounter = 0;
      _ppuNtReadCount = 0;
    } else if (address >= 0x2000 &&
        address <= 0x2fff &&
        _lastPpuAddress == address) {
      _ppuNtReadCount++;
    } else {
      _ppuNtReadCount = 0;
    }
  }

  int _ppuReadSplitMode(int address, bool fetchingNametable) {
    final scroll = (_scanline + _splitScroll) % 240;

    if (address >= 0x2000) {
      if (fetchingNametable) {
        final tile = (_tileCounter + 2) % 42;

        final inSplitRegion = switch (_splitSide) {
          SplitSide.left => tile < _splitTile,
          SplitSide.right => tile >= _splitTile,
        };

        if (tile <= 32 && inSplitRegion) {
          _splitActive = true;
          _splitTileAddress = ((scroll & 0xf8) << 2) | tile;

          return _exram[_splitTileAddress];
        }

        _splitActive = false;
      } else if (_splitActive) {
        return _exram[0x3c0 + ((_splitTileAddress >> 4) & 0x38) |
            ((_splitTileAddress >> 2) & 0x7)];
      }
    } else if (_splitActive) {
      return _readChr((_splitBank << 12) | (address & 0xff8) | (scroll & 0x7));
    }

    return super.ppuRead(address);
  }

  int _ppuReadExtendedAttributes(int address, bool fetchingNametable) {
    if (fetchingNametable) {
      _extendedAttributeOffset = address & 0x3ff;
      _extendedAttributeFetchCountdown = 3;

      return super.ppuRead(address);
    }

    if (_extendedAttributeFetchCountdown == 0) {
      return super.ppuRead(address);
    }

    _extendedAttributeFetchCountdown--;

    switch (_extendedAttributeFetchCountdown) {
      case 2:
        final attribute = _exram[_extendedAttributeOffset];

        _extendedAttributeChrBank = (_chrPageHigh << 6) | (attribute & 0x3f);

        final palette = (attribute & 0xc0) >> 6;

        return palette << 6 | palette << 4 | palette << 2 | palette;
      case 1:
      case 0:
        return _readChr((_extendedAttributeChrBank << 12) + (address & 0xfff));
    }

    return super.ppuRead(address);
  }

  @override
  int cpuRead(int address, {bool disableSideEffects = false}) {
    switch (address) {
      case 0x5010:
      case 0x5015:
        // audio
        return 0;
      case 0x5204:
        final result =
            (_irqPending ? (1 << 7) : 0) | (_ppuInFrame ? (1 << 6) : 0);

        if (!disableSideEffects) {
          _irqPending = false;

          bus.clearIrq(IrqSource.mapper);
        }

        return result;
      case 0x5205:
        return (_multiplicand * _multiplier) & 0xff;
      case 0x5206:
        return ((_multiplicand * _multiplier) >> 8) & 0xff;
      case 0xfffa:
      case 0xfffb:
        if (!disableSideEffects) {
          _ppuInFrame = false;

          _updateChrMapping();

          _lastPpuAddress = 0;
          _scanline = 0;
          _irqPending = false;

          bus.clearIrq(IrqSource.mapper);
        }
    }

    return super.cpuRead(address);
  }

  @override
  void cpuWrite(int address, int value) {
    if (address >= 0x5c00 &&
        address <= 0x5fff &&
        _extendedRamMode <= 1 &&
        !_ppuInFrame) {
      super.cpuWrite(address, 0);

      return;
    }

    switch (address) {
      case >= 0x5000 && <= 0x5015:
        // audio
        break;
      case 0x5100:
        _prgBankMode = value & 0x3;

        _updatePrgMapping();
      case 0x5101:
        _chrBankMode = value & 0x3;

        _updateChrMapping();
      case 0x5102:
        _prgRamProtect1 = value & 0x3;

        _updatePrgMapping();
      case 0x5103:
        _prgRamProtect2 = value & 0x3;

        _updatePrgMapping();
      case 0x5104:
        _extendedRamMode = value & 0x3;

        _updateExtendedRamMode();
      case 0x5105:
        _nametables = value;

        _updateNametables();
      case 0x5106:
        _fillModeTile = value;

        _updateFillTile();
      case 0x5107:
        _fillModeColor = value & 0x3;

        _updateFillColor();
      case >= 0x5113 && <= 0x5117:
        _prgRegisters[address - 0x5113] = value;

        _updatePrgMapping();
      case >= 0x5120 && <= 0x512b:
        final newValue = (_chrPageHigh << 8) | value;

        if (newValue != _chrPage(address) || address != _lastChrAddress) {
          _chrRegisters[address - 0x5120] = newValue;

          _lastChrAddress = address;

          _updateChrMapping();
        }
      case 0x5130:
        _chrPageHigh = value & 0x3;
      case 0x5200:
        _splitEnabled = value.bit(7) == 1;
        _splitSide = switch (value.bit(6)) {
          0 => SplitSide.left,
          _ => SplitSide.right,
        };
        _splitTile = value & 0x1f;
      case 0x5201:
        _splitScroll = value;
      case 0x5202:
        _splitBank = value;
      case 0x5203:
        _irqTargetScanline = value;
      case 0x5204:
        _irqEnabled = value.bit(7) == 1;

        if (!_irqEnabled) {
          bus.clearIrq(IrqSource.mapper);
        } else if (_irqPending) {
          bus.triggerIrq(IrqSource.mapper);
        }
      case 0x5205:
        _multiplicand = value;
      case 0x5206:
        _multiplier = value;
    }

    return super.cpuWrite(address, value);
  }

  void _updateFillTile() {
    _filledNametable.fillRange(0, 0x3bf, _fillModeTile);
  }

  void _updateFillColor() {
    final attribute =
        _fillModeColor << 6 |
        _fillModeColor << 4 |
        _fillModeColor << 2 |
        _fillModeColor;

    _filledNametable.fillRange(0x3c0, 0x3ff, attribute);
  }

  void _updateState() {
    _updatePrgMapping();
    _updateChrMapping();
    _updateExtendedRamMode();
  }

  void _updatePrgMapping() {
    switch (_prgBankMode) {
      case 0:
        _mapCpu(0x6000, 0x7fff, 0);
        _mapCpu(0x8000, 0xffff, 4);
      case 1:
        _mapCpu(0x6000, 0x7fff, 0);
        _mapCpu(0x8000, 0xbfff, 2);
        _mapCpu(0xc000, 0xffff, 4);
      case 2:
        _mapCpu(0x6000, 0x7fff, 0);
        _mapCpu(0x8000, 0xbfff, 2);
        _mapCpu(0xc000, 0xdfff, 3);
        _mapCpu(0xe000, 0xffff, 4);
      case 3:
        _mapCpu(0x6000, 0x7fff, 0);
        _mapCpu(0x8000, 0x9fff, 1);
        _mapCpu(0xa000, 0xbfff, 2);
        _mapCpu(0xc000, 0xdfff, 3);
        _mapCpu(0xe000, 0xffff, 4);
    }
  }

  void _mapCpu(int fromAddress, int toAddress, int register) {
    final memoryType = _memoryType(register);

    mapCpu(
      fromAddress,
      toAddress,
      _prgPage(register),
      type: memoryType,
      access: _memoryAccess(memoryType),
    );
  }

  int _prgPage(int register) {
    final value = _prgRegisters[register] & 0x7f;

    return switch (register) {
      2 => switch (_prgBankMode) {
        1 || 2 => value & 0x7e,
        _ => value,
      },
      4 => switch (_prgBankMode) {
        0 => value & 0x7c,
        1 => value & 0x7e,
        _ => value,
      },
      _ => value,
    };
  }

  CpuMemoryType _memoryType(int register) {
    return switch (register) {
      0 => CpuMemoryType.prgRam,
      4 => CpuMemoryType.prgRom,
      _ => switch ((_prgRegisters[register] >> 7) & 0x1) {
        0 => CpuMemoryType.prgRam,
        _ => CpuMemoryType.prgRom,
      },
    };
  }

  MemoryAccess _memoryAccess(CpuMemoryType memoryType) {
    return switch (memoryType) {
      CpuMemoryType.prgRom => MemoryAccess.read,
      _ =>
        _prgRamProtect1 == 2 && _prgRamProtect2 == 1
            ? MemoryAccess.readWrite
            : MemoryAccess.read,
    };
  }

  void _updateChrMapping() {
    final bigSprites = bus.ppu.PPUCTRL_H == 1;

    final extraChr =
        bigSprites &&
        (_tileCounter < 32 || _tileCounter >= 40) &&
        (_ppuInFrame || _lastChrAddress > 0x5127);

    switch (_chrBankMode) {
      case 0:
        mapPpu(0x0000, 0x1fff, _chrPage(extraChr ? 0x512b : 0x5127) << 3);
      case 1:
        mapPpu(0x0000, 0x0fff, _chrPage(extraChr ? 0x512b : 0x5123) << 2);
        mapPpu(0x1000, 0x1fff, _chrPage(extraChr ? 0x512b : 0x5127) << 2);
      case 2:
        mapPpu(0x0000, 0x07ff, _chrPage(extraChr ? 0x5129 : 0x5121) << 1);
        mapPpu(0x0800, 0x0fff, _chrPage(extraChr ? 0x512b : 0x5123) << 1);
        mapPpu(0x1000, 0x17ff, _chrPage(extraChr ? 0x5129 : 0x5125) << 1);
        mapPpu(0x1800, 0x1fff, _chrPage(extraChr ? 0x512b : 0x5127) << 1);
      case 3:
        mapPpu(0x0000, 0x03ff, _chrPage(extraChr ? 0x5128 : 0x5120));
        mapPpu(0x0400, 0x07ff, _chrPage(extraChr ? 0x5129 : 0x5121));
        mapPpu(0x0800, 0x0bff, _chrPage(extraChr ? 0x512a : 0x5122));
        mapPpu(0x0c00, 0x0fff, _chrPage(extraChr ? 0x512b : 0x5123));
        mapPpu(0x1000, 0x13ff, _chrPage(extraChr ? 0x5128 : 0x5124));
        mapPpu(0x1400, 0x17ff, _chrPage(extraChr ? 0x5129 : 0x5125));
        mapPpu(0x1800, 0x1bff, _chrPage(extraChr ? 0x512a : 0x5126));
        mapPpu(0x1c00, 0x1fff, _chrPage(extraChr ? 0x512b : 0x5127));
    }
  }

  int _chrPage(int address) => _chrRegisters[address - 0x5120];

  void _updateNametables() {
    _updateNametable(0, _nametables & 0x3);
    _updateNametable(1, (_nametables >> 2) & 0x3);
    _updateNametable(2, (_nametables >> 4) & 0x3);
    _updateNametable(3, (_nametables >> 6) & 0x3);
  }

  void _updateNametable(int index, int value) {
    switch (value) {
      case 0:
      case 1:
        setNametable(index, value);
      case 2:
        final source = switch (_extendedRamMode) {
          0 || 1 => _exram,
          _ => _emptyNametable,
        };

        final access = switch (_extendedRamMode) {
          0 || 1 => MemoryAccess.readWrite,
          _ => MemoryAccess.read,
        };

        final offset = index * 0x400;

        mapPpu(
          0x2000 + offset,
          0x23ff + offset,
          0,
          source: source,
          type: PpuMemoryType.nametable,
          access: access,
        );
      case 3:
        final offset = index * 0x400;

        mapPpu(
          0x2000 + offset,
          0x23ff + offset,
          0,
          source: _filledNametable,
          type: PpuMemoryType.nametable,
          access: MemoryAccess.read,
        );
    }
  }

  void _updateExtendedRamMode() {
    final access = switch (_extendedRamMode) {
      0 || 1 => MemoryAccess.write,
      2 => MemoryAccess.readWrite,
      _ => MemoryAccess.read,
    };

    mapCpu(
      0x5c00,
      0x5fff,
      0,
      source: _exram,
      pageSize: _exram.length,
      access: access,
    );

    _updateNametables();
  }

  int _readChr(int address) {
    return cartridge.chrRom[address];
  }
}
