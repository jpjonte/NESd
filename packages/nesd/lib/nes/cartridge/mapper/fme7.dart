import 'dart:typed_data';

import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/apu/expansion/expansion_audio.dart';
import 'package:nesd/nes/apu/expansion/sunsoft5b_audio.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/mapper/fme7_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cpu/irq_source.dart';

class FME7 extends Mapper {
  FME7() : super(69);

  @override
  String name = 'Sunsoft FME-7';

  @override
  int prgRomPageSize = 0x2000;

  @override
  int chrPageSize = 0x400;

  late final Sunsoft5BAudio audio = Sunsoft5BAudio();

  @override
  ExpansionAudio? get expansionAudio => audio;

  int _command = 0;

  final _prgBanks = List.filled(3, 0);

  final _chrBanks = List.filled(8, 0);

  int _workRamBank = 0;

  bool _workRamSelected = false;
  bool _workRamEnabled = false;

  int _arrangement = 0;

  int _irqCounter = 0;

  bool _irqCounterEnabled = false;
  bool _irqEnabled = false;

  static final _unmapped = Uint8List(0);

  @override
  FME7State get state => FME7State(
    command: _command,
    prgBanks: List.of(_prgBanks),
    chrBanks: List.of(_chrBanks),
    workRamBank: _workRamBank,
    workRamSelected: _workRamSelected,
    workRamEnabled: _workRamEnabled,
    arrangement: _arrangement,
    irqCounter: _irqCounter,
    irqCounterEnabled: _irqCounterEnabled,
    irqEnabled: _irqEnabled,
    audioState: audio.state,
  );

  @override
  set state(covariant FME7State state) {
    _command = state.command;

    _prgBanks.setAll(0, state.prgBanks);
    _chrBanks.setAll(0, state.chrBanks);

    _workRamBank = state.workRamBank;
    _workRamSelected = state.workRamSelected;
    _workRamEnabled = state.workRamEnabled;

    _arrangement = state.arrangement;

    _irqCounter = state.irqCounter;
    _irqCounterEnabled = state.irqCounterEnabled;
    _irqEnabled = state.irqEnabled;

    audio.state = state.audioState;

    _updatePrgBanks();
    _updateChrBanks();
    _updateWorkRam();
    _updateArrangement();
  }

  @override
  void reset() {
    super.reset();

    _command = 0;

    _prgBanks.fillRange(0, _prgBanks.length, 0);
    _chrBanks.fillRange(0, _chrBanks.length, 0);

    _workRamBank = 0;
    _workRamSelected = false;
    _workRamEnabled = false;

    _arrangement = switch (cartridge.nametableLayout) {
      NametableLayout.vertical => 1,
      NametableLayout.singleLower => 2,
      NametableLayout.singleUpper => 3,
      NametableLayout.horizontal || NametableLayout.four => 0,
    };

    _irqCounter = 0;
    _irqCounterEnabled = false;
    _irqEnabled = false;

    audio.reset();

    _updatePrgBanks();
    _updateChrBanks();
    _updateWorkRam();
  }

  @override
  bool get needsStep => true;

  @override
  void step() {
    audio.step();

    if (!_irqCounterEnabled) {
      return;
    }

    _irqCounter = (_irqCounter - 1) & 0xffff;

    if (_irqCounter == 0xffff && _irqEnabled) {
      bus.triggerIrq(IrqSource.mapper);
    }
  }

  @override
  void cpuWrite(int address, int value) {
    switch (address & 0xe000) {
      case 0x8000:
        _command = value & 0x0f;

        return;
      case 0xa000:
        _writeParameter(value);

        return;
      case 0xc000:
        audio.writeAddress(value);

        return;
      case 0xe000:
        audio.writeData(value);

        return;
    }

    super.cpuWrite(address, value);
  }

  void _writeParameter(int value) {
    switch (_command) {
      case <= 0x7:
        _chrBanks[_command] = value;

        _updateChrBanks();
      case 0x8:
        _workRamBank = value & 0x3f;
        _workRamSelected = value.bit(6) == 1;
        _workRamEnabled = value.bit(7) == 1;

        _updateWorkRam();
      case 0x9 || 0xa || 0xb:
        _prgBanks[_command - 0x9] = value & 0x3f;

        _updatePrgBanks();
      case 0xc:
        _arrangement = value & 0x3;

        _updateArrangement();
      case 0xd:
        _irqEnabled = value.bit(0) == 1;
        _irqCounterEnabled = value.bit(7) == 1;

        bus.clearIrq(IrqSource.mapper);
      case 0xe:
        _irqCounter = (_irqCounter & 0xff00) | value;
      case 0xf:
        _irqCounter = (value << 8) | (_irqCounter & 0x00ff);
    }
  }

  void _updatePrgBanks() {
    for (var slot = 0; slot < 3; slot++) {
      final address = 0x8000 + slot * 0x2000;

      mapCpu(address, address + 0x1fff, _prgBanks[slot]);
    }

    mapCpu(0xe000, 0xffff, -1);
  }

  void _updateWorkRam() {
    if (!_workRamSelected) {
      mapCpu(0x6000, 0x7fff, _workRamBank);

      return;
    }

    if (!_workRamEnabled) {
      mapCpu(0x6000, 0x7fff, 0, source: _unmapped);

      return;
    }

    mapCpu(0x6000, 0x7fff, _workRamBank, type: _workRamType);
  }

  CpuMemoryType get _workRamType =>
      cartridge.hasBattery && cartridge.prgSaveRam.isNotEmpty
      ? CpuMemoryType.prgSaveRam
      : CpuMemoryType.prgRam;

  void _updateArrangement() {
    nametableLayout = switch (_arrangement) {
      0 => NametableLayout.horizontal,
      1 => NametableLayout.vertical,
      2 => NametableLayout.singleLower,
      _ => NametableLayout.singleUpper,
    };
  }

  void _updateChrBanks() {
    for (var slot = 0; slot < 8; slot++) {
      final address = slot * 0x400;

      mapPpu(address, address + 0x3ff, _chrBanks[slot]);
    }
  }
}
