import 'dart:math';

import 'package:binarize/binarize.dart';
import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';
import 'package:nesd/nes/cartridge/mapper/unrom512_state.dart';

enum _FlashState {
  read,
  unlocked1,
  unlocked2,
  program,
  erasePrimed,
  eraseUnlocked1,
  eraseUnlocked2,
  identify,
}

class UNROM512 extends Mapper {
  UNROM512(int subMapperId) : super(30, subMapperId);

  int latch = 0;

  int get prgBank => latch & 0x1f;

  int get chrBank => (latch >> 5) & 0x03;

  late final bool _lowRegister =
      (subMapperId == 0 && !cartridge.hasBattery) || subMapperId == 2;

  late final bool _flashEnabled = cartridge.hasBattery && subMapperId != 2;

  _FlashState _flashState = _FlashState.read;

  final Set<int> _dirtySectors = {};

  static const _sectorSize = 0x1000;

  static const _manufacturerCode = 0xbf;

  static const _commandAddressMask = 0x7fff;
  static const _unlockAddress1 = 0x5555;
  static const _unlockAddress2 = 0x2aaa;

  @override
  String name = 'UNROM 512';

  @override
  int prgRomPageSize = 0x4000;

  @override
  int chrPageSize = 0x2000;

  @override
  int get minChrRamSize => 0x8000;

  @override
  UNROM512State get state =>
      UNROM512State(latch: latch, flashSectors: _captureFlashSectors());

  @override
  set state(covariant UNROM512State state) {
    latch = state.latch;

    _restoreFlashSectors(state.flashSectors);

    _updateState();
  }

  @override
  Uint8List? save() {
    if (!_flashEnabled || _dirtySectors.isEmpty) {
      return null;
    }

    final writer = Payload.write();

    state.serialize(writer);

    return binarize(writer);
  }

  @override
  void load(Uint8List save) {
    if (!_flashEnabled || save.length < 2 || save[0] != 0 || save[1] != id) {
      return;
    }

    state = MapperState.deserialize(Payload.read(save)) as UNROM512State;
  }

  @override
  void reset() {
    super.reset();

    latch = 0;

    _updateState();
  }

  @override
  void cpuWrite(int address, int value) {
    super.cpuWrite(address, value);

    if (address < 0x8000) {
      return;
    }

    if (address < 0xc000 && !_lowRegister) {
      if (_flashEnabled) {
        _flashWrite(address, value);
      }

      return;
    }

    latch = _lowRegister ? value & cpuRead(address) : value;

    _updateState();
  }

  Map<int, Uint8List> _captureFlashSectors() {
    return {
      for (final sector in _dirtySectors)
        sector: Uint8List.fromList(
          cartridge.prgRom.sublist(
            sector * _sectorSize,
            min((sector + 1) * _sectorSize, cartridge.prgRom.length),
          ),
        ),
    };
  }

  void _restoreFlashSectors(Map<int, Uint8List> sectors) {
    for (final sector in {..._dirtySectors, ...sectors.keys}) {
      final start = sector * _sectorSize;
      final end = min(start + _sectorSize, cartridge.prgRom.length);
      final data = sectors[sector];

      if (data != null) {
        cartridge.prgRom.setRange(start, min(start + data.length, end), data);

        continue;
      }

      cartridge.prgRom.setRange(
        start,
        end,
        cartridge.rom,
        _prgRomOffset + start,
      );
    }

    _dirtySectors
      ..clear()
      ..addAll(sectors.keys);
  }

  int get _prgRomOffset => 16 + (cartridge.hasTrainer ? 512 : 0);

  @override
  int cpuRead(int address, {bool disableSideEffects = false}) {
    if (_flashState == _FlashState.identify &&
        address >= 0x8000 &&
        address < 0xc000) {
      return address.bit(0) == 0 ? _manufacturerCode : _deviceCode;
    }

    return super.cpuRead(address, disableSideEffects: disableSideEffects);
  }

  int get _deviceCode => switch (cartridge.prgRom.length) {
    >= 0x80000 => 0xb7, // 512 KiB
    >= 0x40000 => 0xb6, // 256 KiB
    _ => 0xb5, // 128 KiB
  };

  void _flashWrite(int address, int value) {
    final chipAddress = prgBank * 0x4000 + (address - 0x8000);

    final command = chipAddress & _commandAddressMask;

    switch (_flashState) {
      case _FlashState.read:
        if (command == _unlockAddress1 && value == 0xaa) {
          _flashState = _FlashState.unlocked1;
        }

      case _FlashState.unlocked1:
        _flashState = command == _unlockAddress2 && value == 0x55
            ? _FlashState.unlocked2
            : _FlashState.read;

      case _FlashState.unlocked2:
        _flashState = _commandState(command, value);

      case _FlashState.program:
        _programByte(chipAddress, value);

        _flashState = _FlashState.read;

      case _FlashState.erasePrimed:
        _flashState = command == _unlockAddress1 && value == 0xaa
            ? _FlashState.eraseUnlocked1
            : _FlashState.read;

      case _FlashState.eraseUnlocked1:
        _flashState = command == _unlockAddress2 && value == 0x55
            ? _FlashState.eraseUnlocked2
            : _FlashState.read;

      case _FlashState.eraseUnlocked2:
        _erase(chipAddress, value);

        _flashState = _FlashState.read;

      case _FlashState.identify:
        if (value == 0xf0) {
          _flashState = _FlashState.read;

          return;
        }

        if (command == _unlockAddress1 && value == 0xaa) {
          _flashState = _FlashState.unlocked1;
        }
    }
  }

  _FlashState _commandState(int command, int value) {
    if (command != _unlockAddress1) {
      return _FlashState.read;
    }

    return switch (value) {
      0xa0 => _FlashState.program,
      0x80 => _FlashState.erasePrimed,
      0x90 => _FlashState.identify,
      _ => _FlashState.read,
    };
  }

  void _programByte(int chipAddress, int value) {
    final target = chipAddress % cartridge.prgRom.length;

    cartridge.prgRom[target] &= value;

    _dirtySectors.add(target ~/ _sectorSize);
  }

  void _erase(int chipAddress, int value) {
    switch (value) {
      case 0x10:
        for (var sector = 0; sector < _sectorCount; sector++) {
          _eraseSector(sector);
        }

      case 0x30:
        _eraseSector((chipAddress % cartridge.prgRom.length) ~/ _sectorSize);
    }
  }

  void _eraseSector(int sector) {
    final start = sector * _sectorSize;
    final end = min(start + _sectorSize, cartridge.prgRom.length);

    cartridge.prgRom.fillRange(start, end, 0xff);

    _dirtySectors.add(sector);
  }

  int get _sectorCount =>
      (cartridge.prgRom.length + _sectorSize - 1) ~/ _sectorSize;

  void _updateState() {
    _updateBanks();
    _updateMirroring();
  }

  void _updateBanks() {
    mapCpu(0x8000, 0xbfff, prgBank);
    mapCpu(0xc000, 0xffff, -1);
    mapPpu(0x0000, 0x1fff, chrBank);
  }

  void _updateMirroring() {
    if (subMapperId == 3) {
      nametableLayout = latch.bit(7) == 0
          ? NametableLayout.vertical
          : NametableLayout.horizontal;

      return;
    }

    if (!cartridge.alternativeNametableLayout ||
        cartridge.nametableLayout == NametableLayout.horizontal) {
      nametableLayout = cartridge.nametableLayout;

      return;
    }

    nametableLayout = latch.bit(7) == 0
        ? NametableLayout.singleLower
        : NametableLayout.singleUpper;
  }
}
