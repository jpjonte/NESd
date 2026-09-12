import 'dart:typed_data';

import 'package:nesd/exception/unsupported_mapper.dart';
import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/vrc24_state.dart';
import 'package:nesd/nes/cpu/irq_source.dart';

class VRC24Variant {
  const VRC24Variant({
    required this.line0,
    required this.line1,
    this.vrc2 = false,
    this.chrShift = 0,
  });

  factory VRC24Variant.fromIds(int mapperId, int subMapperId) {
    return switch ((mapperId, subMapperId)) {
      (21, 1) => const VRC24Variant(line0: 0x02, line1: 0x04), // VRC4a
      (21, 2) => const VRC24Variant(line0: 0x40, line1: 0x80), // VRC4c
      (21, _) => const VRC24Variant(line0: 0x42, line1: 0x84),
      (22, _) => const VRC24Variant(
        line0: 0x02,
        line1: 0x01,
        vrc2: true,
        chrShift: 1,
      ), // VRC2a
      (23, 1) => const VRC24Variant(line0: 0x01, line1: 0x02), // VRC4f
      (23, 2) => const VRC24Variant(line0: 0x04, line1: 0x08), // VRC4e
      (23, 3) => const VRC24Variant(line0: 0x01, line1: 0x02, vrc2: true),
      (23, _) => const VRC24Variant(line0: 0x05, line1: 0x0a),
      (25, 1) => const VRC24Variant(line0: 0x02, line1: 0x01), // VRC4b
      (25, 2) => const VRC24Variant(line0: 0x08, line1: 0x04), // VRC4d
      (25, 3) => const VRC24Variant(line0: 0x02, line1: 0x01, vrc2: true),
      (25, _) => const VRC24Variant(line0: 0x0a, line1: 0x05),
      _ => throw UnsupportedMapper(mapperId, subMapperId),
    };
  }

  final int line0;
  final int line1;

  final bool vrc2;

  /// VRC2a ignores the low bit of every CHR bank number.
  final int chrShift;

  int registerIndex(int address) =>
      (address & line0 != 0 ? 1 : 0) | (address & line1 != 0 ? 2 : 0);

  int registerAddress(int index) =>
      (index & 1 != 0 ? line0 : 0) | (index & 2 != 0 ? line1 : 0);
}

class VRC24 extends Mapper {
  VRC24(super.id, super.subMapperId);

  late final VRC24Variant variant = VRC24Variant.fromIds(id, subMapperId);

  @override
  String get name => variant.vrc2 ? 'Konami VRC2' : 'Konami VRC4';

  @override
  int prgRomPageSize = 0x2000;

  @override
  int chrPageSize = 0x400;

  static const _prescalerPeriod = 341;

  static final _unmapped = Uint8List(0);

  final _prgBanks = List.filled(2, 0);

  final _chrBanks = List.filled(8, 0);

  int _mirroring = 0;

  bool _swapMode = false;

  bool _workRamEnabled = true;

  int _latch = 0;

  int _irqLatch = 0;
  int _irqCounter = 0;
  int _irqPrescaler = _prescalerPeriod;

  bool _irqEnabled = false;
  bool _irqEnableAfterAck = false;
  bool _irqCycleMode = false;

  @override
  VRC24State get state => VRC24State(
    id: id,
    prgBanks: List.of(_prgBanks),
    chrBanks: List.of(_chrBanks),
    mirroring: _mirroring,
    swapMode: _swapMode,
    workRamEnabled: _workRamEnabled,
    latch: _latch,
    irqLatch: _irqLatch,
    irqCounter: _irqCounter,
    irqPrescaler: _irqPrescaler,
    irqEnabled: _irqEnabled,
    irqEnableAfterAck: _irqEnableAfterAck,
    irqCycleMode: _irqCycleMode,
  );

  @override
  set state(covariant VRC24State state) {
    _prgBanks.setAll(0, state.prgBanks);
    _chrBanks.setAll(0, state.chrBanks);

    _mirroring = state.mirroring;
    _swapMode = state.swapMode;
    _workRamEnabled = state.workRamEnabled;
    _latch = state.latch;

    _irqLatch = state.irqLatch;
    _irqCounter = state.irqCounter;
    _irqPrescaler = state.irqPrescaler;
    _irqEnabled = state.irqEnabled;
    _irqEnableAfterAck = state.irqEnableAfterAck;
    _irqCycleMode = state.irqCycleMode;

    _updatePrgBanks();
    _updateChrBanks();
    _updateMirroring();
    _updateWorkRam();
  }

  @override
  void reset() {
    super.reset();

    _prgBanks.fillRange(0, _prgBanks.length, 0);
    _chrBanks.fillRange(0, _chrBanks.length, 0);

    _mirroring = switch (cartridge.nametableLayout) {
      NametableLayout.vertical => 1,
      NametableLayout.singleLower => 2,
      NametableLayout.singleUpper => 3,
      NametableLayout.horizontal || NametableLayout.four => 0,
    };

    _swapMode = false;
    _workRamEnabled = true;
    _latch = 0;

    _irqLatch = 0;
    _irqCounter = 0;
    _irqPrescaler = _prescalerPeriod;
    _irqEnabled = false;
    _irqEnableAfterAck = false;
    _irqCycleMode = false;

    _updatePrgBanks();
    _updateChrBanks();
  }

  @override
  bool get needsStep => !variant.vrc2;

  @override
  void step() {
    if (!_irqEnabled) {
      return;
    }

    if (_irqCycleMode) {
      _clockIrq();

      return;
    }

    _irqPrescaler -= 3;

    if (_irqPrescaler <= 0) {
      _irqPrescaler += _prescalerPeriod;

      _clockIrq();
    }
  }

  void _clockIrq() {
    if (_irqCounter != 0xff) {
      _irqCounter++;

      return;
    }

    _irqCounter = _irqLatch;

    bus.triggerIrq(IrqSource.mapper);
  }

  @override
  int cpuRead(int address, {bool disableSideEffects = false}) {
    if (_isLatchAddress(address)) {
      return (bus.cpu.openBus & 0xfe) | _latch;
    }

    return super.cpuRead(address, disableSideEffects: disableSideEffects);
  }

  @override
  void cpuWrite(int address, int value) {
    if (address < 0x8000) {
      if (_isLatchAddress(address)) {
        _latch = value & 0x01;

        return;
      }

      super.cpuWrite(address, value);

      return;
    }

    final index = variant.registerIndex(address);

    switch (address & 0xf000) {
      case 0x8000:
        _prgBanks[0] = value & 0x1f;

        _updatePrgBanks();
      case 0x9000:
        _writeControl(index, value);
      case 0xa000:
        _prgBanks[1] = value & 0x1f;

        _updatePrgBanks();
      case 0xb000 || 0xc000 || 0xd000 || 0xe000:
        _writeChr(((address >> 12) - 0xb) * 2 + (index >> 1), index, value);
      case 0xf000:
        if (!variant.vrc2) {
          _writeIrq(index, value);
        }
    }
  }

  bool _isLatchAddress(int address) =>
      address >= 0x6000 && address <= 0x6fff && !_hasWorkRam;

  bool get _hasWorkRam =>
      cartridge.prgRam.isNotEmpty ||
      (cartridge.hasBattery && cartridge.prgSaveRam.isNotEmpty);

  void _writeControl(int index, int value) {
    if (variant.vrc2) {
      _mirroring = value & 0x01;

      _updateMirroring();

      return;
    }

    if (index < 2) {
      _mirroring = value & 0x03;

      _updateMirroring();

      return;
    }

    _workRamEnabled = value.bit(0) == 1;
    _swapMode = value.bit(1) == 1;

    _updateWorkRam();
    _updatePrgBanks();
  }

  void _writeChr(int slot, int index, int value) {
    final current = _chrBanks[slot];

    _chrBanks[slot] = index.isEven
        ? (current & 0x1f0) | (value & 0x0f)
        : (current & 0x00f) | ((value & _chrHighMask) << 4);

    _mapChrSlot(slot);
  }

  int get _chrHighMask => variant.vrc2 ? 0x0f : 0x1f;

  void _writeIrq(int index, int value) {
    switch (index) {
      case 0:
        _irqLatch = (_irqLatch & 0xf0) | (value & 0x0f);
      case 1:
        _irqLatch = (_irqLatch & 0x0f) | ((value & 0x0f) << 4);
      case 2:
        _irqEnableAfterAck = value.bit(0) == 1;
        _irqEnabled = value.bit(1) == 1;
        _irqCycleMode = value.bit(2) == 1;
        _irqPrescaler = _prescalerPeriod;

        if (_irqEnabled) {
          _irqCounter = _irqLatch;
        }

        bus.clearIrq(IrqSource.mapper);
      case 3:
        _irqEnabled = _irqEnableAfterAck;

        bus.clearIrq(IrqSource.mapper);
    }
  }

  void _updatePrgBanks() {
    mapCpu(0x8000, 0x9fff, _swapMode ? -2 : _prgBanks[0]);
    mapCpu(0xa000, 0xbfff, _prgBanks[1]);
    mapCpu(0xc000, 0xdfff, _swapMode ? _prgBanks[0] : -2);
    mapCpu(0xe000, 0xffff, -1);
  }

  void _updateChrBanks() {
    for (var slot = 0; slot < 8; slot++) {
      _mapChrSlot(slot);
    }
  }

  void _mapChrSlot(int slot) {
    final address = slot * 0x400;

    mapPpu(address, address + 0x3ff, _chrBanks[slot] >> variant.chrShift);
  }

  void _updateMirroring() {
    nametableLayout = switch (_mirroring) {
      0 => NametableLayout.horizontal,
      1 => NametableLayout.vertical,
      2 => NametableLayout.singleLower,
      _ => NametableLayout.singleUpper,
    };
  }

  void _updateWorkRam() {
    if (!_hasWorkRam) {
      return;
    }

    if (!variant.vrc2 && !_workRamEnabled) {
      mapCpu(0x6000, 0x7fff, 0, source: _unmapped);

      return;
    }

    mapCpu(0x6000, 0x7fff, 0, type: _workRamType);
  }

  CpuMemoryType get _workRamType =>
      cartridge.hasBattery && cartridge.prgSaveRam.isNotEmpty
      ? CpuMemoryType.prgSaveRam
      : CpuMemoryType.prgRam;
}
