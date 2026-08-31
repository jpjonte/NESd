import 'dart:typed_data';

import 'package:nesd/nes/cartridge/mapper/chip/a12_edge_detector.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/vt/vt02_state.dart';

abstract class VT02 extends Mapper {
  VT02(super.id, [super.subMapperId = 0]);

  /// `0x4100` - `0x411b`
  final Uint8List _systemRegisters = Uint8List(0x1c);

  /// `0x2010` - `0x201f`
  final Uint8List _graphicsRegisters = Uint8List(0x10);

  /// `0x4034` and `0x4035`
  final Uint8List _extraRegisters = Uint8List(2);

  final a12Detector = A12EdgeDetector();

  @override
  bool get needsExtendedPpuRegisters => true;

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

    a12Detector.lowStart = 0;
  }

  @override
  int cpuRead(int address, {bool disableSideEffects = false}) {
    if (_isReadableSystemRegister(address)) {
      return _systemRegisters[address - 0x4100];
    }

    // 0x4035 is the only readable extra register
    if (address == 0x4035) {
      return _extraRegisters[1];
    }

    return super.cpuRead(address, disableSideEffects: disableSideEffects);
  }

  @override
  void cpuWrite(int address, int value) {
    if (address >= 0x4100 && address <= 0x411b) {
      if (_isWritableSystemRegister(address)) {
        _systemRegisters[address - 0x4100] = value;
      }

      return;
    }

    if (address == 0x4034 || address == 0x4035) {
      _extraRegisters[address - 0x4034] = value;

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
    timerCounter: 0,
    timerRunning: false,
    timerEnabled: false,
    a12LowStart: a12Detector.lowStart,
    lastScanline: 0,
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

    _graphicsRegisters[0x00] = state.extendedControl1;
    _graphicsRegisters[0x01] = state.extendedControl2;
    _graphicsRegisters.setRange(0x02, 0x08, state.videoBanks);
    _graphicsRegisters[0x08] = state.videoBank1;
    _graphicsRegisters[0x0a] = state.videoBank0Select;

    a12Detector.lowStart = state.a12LowStart;
  }
}
