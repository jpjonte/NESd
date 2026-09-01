import 'dart:typed_data';

import 'package:nesd/extension/bit_extension.dart';
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
  bool get needsExtendedPpuRegisters => true;

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

    _updatePrgBanks();
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

  @override
  void updatePpuAddress(int address) {
    if (_hsyncClock) {
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

  @override
  void cpuWrite(int address, int value) {
    if (address >= 0x4100 && address <= 0x411b) {
      switch (address) {
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

      if (_isWritableSystemRegister(address)) {
        _systemRegisters[address - 0x4100] = value;
      }

      if (_isPrgBankRegister(address)) {
        _updatePrgBanks();
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

    super.cpuWrite(address, value);
  }

  @override
  void extendedPpuWrite(int address, int value) {
    if (address == 0x2019 || address == 0x201b) {
      return;
    }

    if (address >= 0x201c) {
      return;
    }

    _graphicsRegisters[address - 0x2010] = value;
  }

  bool _isPrgBankRegister(int address) =>
      address == 0x4100 ||
      address == 0x4105 ||
      (address >= 0x4107 && address <= 0x410b);

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

    _updatePrgBanks();
  }
}
