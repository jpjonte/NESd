import 'dart:typed_data';

import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/mapper/chip/a12_edge_detector.dart';
import 'package:nesd/nes/cartridge/mapper/dma_settings.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/vt/vt02_state.dart';
import 'package:nesd/nes/cartridge/mapper/vt/vt02_timer.dart';
import 'package:nesd/nes/cpu/irq_source.dart';
import 'package:nesd/nes/region.dart';

abstract class VT02 extends Mapper {
  VT02(super.id, [super.subMapperId = 0]);

  /// `0x4100` - `0x411b`
  final Uint8List _systemRegisters = Uint8List(0x1c);

  /// `0x2010` - `0x201f`
  final Uint8List _graphicsRegisters = Uint8List(0x10);

  /// `0x4034` and `0x4035`
  final Uint8List _extraRegisters = Uint8List(2);

  DmaSettings _dmaSettings = DmaSettings.fromRegister(0);

  final a12Detector = A12EdgeDetector();

  final timer = VT02Timer();

  int _lastScanline = 0;

  @override
  int get prgRomPageSize => 0x2000;

  @override
  int get chrPageSize => 0x400;

  @override
  bool get needsExtendedPpuRegisters => true;

  @override
  bool get hasExtendedPalette => true;

  bool get _hsyncClock => _systemRegisters[0x0b].bit(7) == 1;

  @override
  bool get needsPpuAddressUpdates => true;

  @override
  bool get needsStep => true;

  @override
  bool get handlesDma => true;

  @override
  void startDma(int page) => bus.cpu.triggerOamDma(page);

  @override
  DmaSettings get dmaSettings => _dmaSettings;

  int registerAt(int address) {
    if (address >= 0x4100 && address <= 0x411b) {
      return _systemRegisters[address - 0x4100];
    }

    if (address >= 0x2010 && address <= 0x201f) {
      return _graphicsRegisters[address - 0x2010];
    }

    if (address == 0x4034 || address == 0x4035) {
      return _extraRegisters[address - 0x4034];
    }

    return 0;
  }

  @override
  void reset() {
    super.reset();

    _systemRegisters.fillRange(0, _systemRegisters.length, 0);
    _graphicsRegisters.fillRange(0, _graphicsRegisters.length, 0);
    _extraRegisters.fillRange(0, _extraRegisters.length, 0);
    _dmaSettings = DmaSettings.fromRegister(0);

    a12Detector.lowStart = 0;

    timer.reset();

    _lastScanline = 0;

    _pushVideoMode();
    _updatePrgBanks();
    _updateChrBanks();
    _updateMirroring();
  }

  void _updatePrgBanks() {
    for (var slot = 0; slot < 4; slot++) {
      final address = 0x8000 + slot * 0x2000;

      mapCpu(address, address + 0x1fff, _prgBank(slot));
    }
  }

  int _prgBank(int slot) {
    final innerMask = _prgInnerMask;
    final inner = _prgInnerBank(slot) & innerMask;
    final middle = _pq3 & ~innerMask & 0xff;

    return (_prgOuterBank << 8) | middle | inner;
  }

  int get _prgOuterBank => _systemRegisters[0x00] >> 4;

  int _prgInnerBank(int slot) => switch (slot) {
    0 => _comr6 ? _pq2 : _pq0,
    1 => _pq1,
    2 => _comr6 ? _pq0 : _pq2,
    _ => 0xff,
  };

  int get _prgInnerMask {
    final mode = _systemRegisters[0x0b] & 0x07;

    return mode == 7 ? 0xff : 0x3f >> mode;
  }

  int get _pq0 => _systemRegisters[0x07];

  int get _pq1 => _systemRegisters[0x08];

  int get _pq2 => _pq2Enabled ? _systemRegisters[0x09] : 0xfe;

  int get _pq3 => _systemRegisters[0x0a];

  bool get _pq2Enabled => _systemRegisters[0x0b].bit(6) == 1;

  bool get _comr6 => _systemRegisters[0x05].bit(6) == 1;

  bool get _fourBppActive => _graphicsRegisters[0x00] & 0x06 != 0;

  bool get _extensionActive => _graphicsRegisters[0x00] & 0x18 != 0;

  void _pushVideoMode() {
    final control = _graphicsRegisters[0x00];
    final eva12s = _graphicsRegisters[0x01].bit(0) == 1;

    bus.ppu
      ..bgFourBpp = control.bit(1) == 1
      ..spriteFourBpp = control.bit(2) == 1
      ..wideVideoBus = control.bit(6) == 1
      ..extendedColors = control.bit(7) == 1
      ..spriteSixteenPixels = control.bit(0) == 1
      ..spriteExtension = control.bit(3) == 1
      ..bgExtension = control.bit(4) == 1
      ..bgEvaBit2 = eva12s
          ? _systemRegisters[0x06].bit(0)
          : _graphicsRegisters[0x08].bit(3)
      ..vrwb = _graphicsRegisters[0x08] & 0x07;
  }

  void _updateChrBanks() {
    final source = _chrSource;

    for (var slot = 0; slot < 8; slot++) {
      final address = slot * 0x400;

      mapPpu(
        address,
        address + 0x3ff,
        _chrBank(slot),
        source: source,
        type: PpuMemoryType.chrRom,
      );
    }

    if (_fourBppActive) {
      for (var slot = 0; slot < 8; slot++) {
        final address = slot * 0x800;

        mapPpu4bpp(address, address + 0x7ff, _chrBank(slot), source: source);
      }
    }

    if (_extensionActive) {
      _updateEvaBanks();
    }
  }

  void _updateEvaBanks() {
    final source = _chrSource;

    for (var eva = 0; eva < 8; eva++) {
      for (var slot = 0; slot < 8; slot++) {
        final bank = _evaBank(slot) | eva;
        final address2bpp = slot * 0x400;
        final address4bpp = slot * 0x800;

        mapPpuEva2bpp(
          eva,
          address2bpp,
          address2bpp + 0x3ff,
          bank,
          source: source,
        );

        mapPpuEva4bpp(
          eva,
          address4bpp,
          address4bpp + 0x7ff,
          bank,
          source: source,
        );
      }
    }
  }

  int _evaBank(int slot) {
    final innerMask = _chrInnerMask;
    final inner = _chrInnerBank(slot) & innerMask;
    final middle = _chrMiddleBank & ~innerMask & 0xff;

    return ((inner | middle) << 3) | (_chrOuterBank << 11);
  }

  Uint8List get _chrSource =>
      cartridge.chrRom.isEmpty ? cartridge.prgRom : cartridge.chrRom;

  int _chrBank(int slot) {
    final innerMask = _chrInnerMask;
    final inner = _chrInnerBank(slot) & innerMask;
    final middle = _chrMiddleBank & ~innerMask & 0xff;

    return (_chrOuterBank << 11) | (_chrIntermediateBank << 8) | middle | inner;
  }

  int get _chrOuterBank => _systemRegisters[0x00] & 0x0f;

  int get _chrIntermediateBank => (_graphicsRegisters[0x08] >> 4) & 0x07;

  int get _chrMiddleBank => _graphicsRegisters[0x0a];

  /// Modes 3 and 7 are undocumented. FCEUX treats them as mode 0.
  static const _chrInnerMasks = [
    0xff,
    0x7f,
    0x3f,
    0xff,
    0x1f,
    0x0f,
    0x07,
    0xff,
  ];

  int get _chrInnerMask => _chrInnerMasks[_graphicsRegisters[0x0a] & 0x07];

  int _chrInnerBank(int slot) {
    final source = _comr7 ? slot ^ 4 : slot;

    return switch (source) {
      0 => _rv(4) & 0xfe,
      1 => _rv(4) | 0x01,
      2 => _rv(5) & 0xfe,
      3 => _rv(5) | 0x01,
      _ => _rv(source - 4),
    };
  }

  int _rv(int n) => _graphicsRegisters[0x02 + n];

  bool get _comr7 => _systemRegisters[0x05].bit(7) == 1;

  void _updateMirroring() {
    nametableLayout = _systemRegisters[0x06].bit(0) == 0
        ? NametableLayout.horizontal
        : NametableLayout.vertical;
  }

  @override
  void updatePpuAddress(int address) {
    if (_hsyncClock) {
      return;
    }

    if (bus.ppu.PPUMASK & 0x18 == 0) {
      return;
    }

    if (!a12Detector.detect(address, bus.cpu.cycles)) {
      return;
    }

    _tickTimer();
  }

  @override
  void step() {
    if (!_hsyncClock) {
      return;
    }

    final scanline = bus.ppu.scanline;

    if (scanline == _lastScanline) {
      return;
    }

    _lastScanline = scanline;

    _tickTimer();
  }

  void _tickTimer() {
    if (timer.tick()) {
      bus.triggerIrq(IrqSource.mapper);
    }
  }

  @override
  int cpuRead(int address, {bool disableSideEffects = false}) {
    if (address == 0x4119) {
      return _rs232Flags;
    }

    if (_isReadableSystemRegister(address)) {
      return _systemRegisters[address - 0x4100];
    }

    // 0x4035 is the only readable extra register
    if (address == 0x4035) {
      return _extraRegisters[1];
    }

    return super.cpuRead(address, disableSideEffects: disableSideEffects);
  }

  int get _rs232Flags {
    const transmitComplete = 0x40;

    return switch (bus.region) {
      Region.ntsc => transmitComplete,
      Region.pal => transmitComplete | 0x08 | 0x10,
    };
  }

  int _scrambledSystemAddress(int address) {
    if (subMapperId != 2) {
      return address;
    }

    return switch (address) {
      0x4107 => 0x4108,
      0x4108 => 0x4107,
      _ => address,
    };
  }

  @override
  void cpuWrite(int address, int value) {
    if (address >= 0x4100 && address <= 0x411b) {
      final target = _scrambledSystemAddress(address);

      switch (target) {
        case 0x4101:
          timer.preload = value;
        case 0x4102:
          timer.load();
        case 0x4103:
          timer.enabled = false;
          bus.clearIrq(IrqSource.mapper);
        case 0x4104:
          timer.enabled = true;
        case 0x410b:
          if ((_systemRegisters[0x0b] ^ value) & 0x80 != 0) {
            a12Detector.lowStart = 0;
          }
      }

      if (_isWritableSystemRegister(target)) {
        _systemRegisters[target - 0x4100] = value;
      }

      if (_isPrgBankRegister(target)) {
        _updatePrgBanks();
      }

      if (_isChrControlRegister(target)) {
        _updateChrBanks();
      }

      if (target == 0x4106) {
        _updateMirroring();
        _pushVideoMode();
      }

      return;
    }

    if (address == 0x4034 || address == 0x4035) {
      _extraRegisters[address - 0x4034] = value;

      if (address == 0x4034) {
        _dmaSettings = DmaSettings.fromRegister(value);
      }

      return;
    }

    if (address >= 0x8000 && !_forwardingDisabled) {
      _forwardMmc3Write(address, value);

      return;
    }

    super.cpuWrite(address, value);
  }

  bool get _forwardingDisabled => _systemRegisters[0x0b].bit(3) == 1;

  void _forwardMmc3Write(int address, int value) {
    switch (address & 0xe001) {
      case 0x8000:
        cpuWrite(0x4105, (_systemRegisters[0x05] & 0x20) | (value & 0xdf));
      case 0x8001:
        _writeRegister(_mmc3BankTarget(_systemRegisters[0x05] & 0x07), value);
      case 0xa000:
        cpuWrite(0x4106, (_systemRegisters[0x06] & 0xfe) | (value & 0x01));
      case 0xc000:
        cpuWrite(0x4101, value);
      case 0xc001:
        cpuWrite(0x4102, value);
      case 0xe000:
        cpuWrite(0x4103, value);
      case 0xe001:
        cpuWrite(0x4104, value);
    }
  }

  static const _mmc3BankTargets = [
    0x2016,
    0x2017,
    0x2012,
    0x2013,
    0x2014,
    0x2015,
    0x4107,
    0x4108,
  ];

  static const _scrambledMmc3BankTargets = <int, List<int>>{
    1: [0x2015, 0x2014, 0x2013, 0x2012, 0x2017, 0x2016, 0x4107, 0x4108],
  };

  int _mmc3BankTarget(int register) =>
      (_scrambledMmc3BankTargets[subMapperId] ?? _mmc3BankTargets)[register];

  void _writeRegister(int address, int value) {
    if (address < 0x4000) {
      _storeGraphicsRegister(address, value);
    } else {
      cpuWrite(address, value);
    }
  }

  static const _nativeChrScrambles = <int, List<int>>{
    1: [0x2013, 0x2012, 0x2017, 0x2016, 0x2015, 0x2014],
    3: [0x2017, 0x2016, 0x2015, 0x2014, 0x2012, 0x2013],
    4: [0x2014, 0x2017, 0x2012, 0x2016, 0x2015, 0x2013],
    5: [0x2013, 0x2012, 0x2017, 0x2016, 0x2016, 0x2017],
  };

  int _scrambledGraphicsAddress(int address) {
    if (address < 0x2012 || address > 0x2017) {
      return address;
    }

    final scramble = _nativeChrScrambles[subMapperId];

    if (scramble == null) {
      return address;
    }

    return scramble[address - 0x2012];
  }

  @override
  void extendedPpuWrite(int address, int value) {
    if (address == 0x2019 || address == 0x201b) {
      return;
    }

    if (address >= 0x201c) {
      return;
    }

    _storeGraphicsRegister(_scrambledGraphicsAddress(address), value);
  }

  void _storeGraphicsRegister(int address, int value) {
    final previous = _graphicsRegisters[address - 0x2010];

    _graphicsRegisters[address - 0x2010] = value;

    if (address == 0x2010 || address == 0x2011 || address == 0x2018) {
      _pushVideoMode();
    }

    if (address == 0x2010 && (previous ^ value) & 0x1e != 0) {
      _updateChrBanks();
    }

    if (_isChrBankRegister(address)) {
      _updateChrBanks();
    }
  }

  bool _isPrgBankRegister(int address) =>
      address == 0x4100 ||
      address == 0x4105 ||
      (address >= 0x4107 && address <= 0x410b);

  bool _isChrControlRegister(int address) =>
      address == 0x4100 || address == 0x4105;

  bool _isChrBankRegister(int address) =>
      (address >= 0x2012 && address <= 0x2018) || address == 0x201a;

  bool _isReadableSystemRegister(int address) =>
      address == 0x410e || address == 0x410f || address == 0x411b;

  bool _isWritableSystemRegister(int address) {
    if (address == 0x410c) {
      return false;
    }

    if (address >= 0x4110 && address <= 0x4113) {
      return false;
    }

    if (address >= 0x4116 && address <= 0x4118) {
      return false;
    }

    if (address == 0x411b) {
      return false;
    }

    return true;
  }

  @override
  VT02State get state => VT02State(
    id: id,
    bank1: _systemRegisters[0x00],
    timerPreload: _systemRegisters[0x01],
    decodeControl: _systemRegisters[0x05],
    scrollSelect: _systemRegisters[0x06],
    programBanks: _systemRegisters.sublist(0x07, 0x0b),
    bankControl: _systemRegisters[0x0b],
    ioControl: _systemRegisters[0x0d],
    ioData01: _systemRegisters[0x0e],
    ioData23: _systemRegisters[0x0f],
    rs232TimerLow: _systemRegisters[0x14],
    rs232TimerHigh: _systemRegisters[0x15],
    rs232Control: _systemRegisters[0x19],
    rs232TxData: _systemRegisters[0x1a],
    dmaControl: _extraRegisters[0],
    xop2: _extraRegisters[1],
    extendedControl1: _graphicsRegisters[0x00],
    extendedControl2: _graphicsRegisters[0x01],
    videoBanks: _graphicsRegisters.sublist(0x02, 0x08),
    videoBank1: _graphicsRegisters[0x08],
    videoBank0Select: _graphicsRegisters[0x0a],
    timerCounter: timer.counter,
    timerRunning: timer.running,
    timerEnabled: timer.enabled,
    a12LowStart: a12Detector.lowStart,
    lastScanline: _lastScanline,
  );

  @override
  set state(covariant VT02State state) {
    _systemRegisters[0x00] = state.bank1;
    _systemRegisters[0x01] = state.timerPreload;
    _systemRegisters[0x05] = state.decodeControl;
    _systemRegisters[0x06] = state.scrollSelect;
    _systemRegisters.setRange(0x07, 0x0b, state.programBanks);
    _systemRegisters[0x0b] = state.bankControl;
    _systemRegisters[0x0d] = state.ioControl;
    _systemRegisters[0x0e] = state.ioData01;
    _systemRegisters[0x0f] = state.ioData23;
    _systemRegisters[0x14] = state.rs232TimerLow;
    _systemRegisters[0x15] = state.rs232TimerHigh;
    _systemRegisters[0x19] = state.rs232Control;
    _systemRegisters[0x1a] = state.rs232TxData;

    _extraRegisters[0] = state.dmaControl;
    _extraRegisters[1] = state.xop2;
    _dmaSettings = DmaSettings.fromRegister(_extraRegisters[0]);

    _graphicsRegisters[0x00] = state.extendedControl1;
    _graphicsRegisters[0x01] = state.extendedControl2;
    _graphicsRegisters.setRange(0x02, 0x08, state.videoBanks);
    _graphicsRegisters[0x08] = state.videoBank1;
    _graphicsRegisters[0x0a] = state.videoBank0Select;

    a12Detector.lowStart = state.a12LowStart;

    timer.preload = state.timerPreload;
    timer.counter = state.timerCounter;
    timer.running = state.timerRunning;
    timer.enabled = state.timerEnabled;

    _lastScanline = state.lastScanline;

    _pushVideoMode();
    _updatePrgBanks();
    _updateChrBanks();
    _updateMirroring();
  }
}
