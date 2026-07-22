import 'dart:math';
import 'dart:typed_data';

import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/mapper/bandai_fcg_state.dart';
import 'package:nesd/nes/cartridge/mapper/chip/eeprom_24c02.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cpu/irq_source.dart';

class BandaiFCG extends Mapper {
  BandaiFCG(int subMapperId, int prgSaveRamSize)
    : _enableFcg1_2 = subMapperId == 0 || subMapperId == 4,
      _enableLZ93D50 = subMapperId == 0 || subMapperId == 5,
      super(16, subMapperId) {
    _eeprom = _enableLZ93D50 && prgSaveRamSize == 256 ? Eeprom24C02() : null;
  }

  @override
  String name = 'Bandai FCG';

  @override
  BandaiFCGState get state => BandaiFCGState(
    chrPages: List.of(_chrPages),
    prgPage: _prgPage,
    nametableLayout: _nametableLayout ?? cartridge.nametableLayout,
    irqEnabled: _irqEnabled,
    irqCounter: _irqCounter,
    irqLatch: _irqLatch,
    eeprom: _eeprom?.state,
  );

  @override
  set state(covariant BandaiFCGState state) {
    _chrPages.setAll(0, state.chrPages);

    _prgPage = state.prgPage;

    _updateNametableLayout(state.nametableLayout);

    _irqEnabled = state.irqEnabled;
    _irqCounter = state.irqCounter;
    _irqLatch = state.irqLatch;

    if (state.eeprom case final eepromState?) {
      _eeprom?.state = eepromState;
    }

    _updateCpuMapping();
    _updatePpuMapping();
  }

  @override
  Uint8List? save() {
    return _eeprom?.data;
  }

  @override
  void load(Uint8List save) {
    if (_eeprom case final eeprom?) {
      eeprom.data.setRange(0, min(eeprom.data.length, save.length), save);
    }
  }

  @override
  int prgRomPageSize = 0x4000;

  @override
  int chrPageSize = 0x400;

  @override
  bool get needsStep => true;

  final bool _enableFcg1_2;
  final bool _enableLZ93D50;

  late final Eeprom24C02? _eeprom;

  final _chrPages = List.generate(8, (i) => i, growable: false);

  int _prgPage = 0;

  // null until the game writes register 9; until then the header
  // layout applied by Mapper.reset stays in effect
  NametableLayout? _nametableLayout;

  bool _irqEnabled = false;
  int _irqLatch = 0;
  int _irqCounter = 0;

  @override
  void reset() {
    super.reset();

    _prgPage = 0;

    for (var i = 0; i < 8; i++) {
      _chrPages[i] = i;
    }

    if (_nametableLayout case final layout?) {
      nametableLayout = layout;
    }

    _irqEnabled = false;
    _irqLatch = 0;
    _irqCounter = 0;

    _eeprom?.reset();

    _updateCpuMapping();
    _updatePpuMapping();
  }

  @override
  void step() {
    if (_irqEnabled) {
      _irqCounter = (_irqCounter - 1) & 0xffff;

      if (_irqCounter == 0) {
        bus.triggerIrq(IrqSource.mapper);
      }
    }
  }

  @override
  int cpuRead(int address, {bool disableSideEffects = false}) {
    if (_eeprom case final eeprom?
        when address >= 0x6000 && address < 0x8000 && _enableLZ93D50) {
      return 0.setBit(4, eeprom.output);
    }

    return super.cpuRead(address, disableSideEffects: disableSideEffects);
  }

  @override
  void cpuWrite(int address, int value) {
    if (_enableFcg1_2 && address >= 0x6000 && address < 0x8000) {
      _cpuWriteFcg1_2(address, value);

      return;
    }

    if (_enableLZ93D50 && address >= 0x8000) {
      _cpuWriteLZ93D50(address, value);

      return;
    }

    super.cpuWrite(address, value);
  }

  void _updateCpuMapping() {
    mapCpu(0x8000, 0xbfff, _prgPage);
    mapCpu(0xc000, 0xffff, -1);
  }

  void _updatePpuMapping() {
    for (var i = 0; i < 8; i++) {
      mapPpu(0x400 * i, 0x400 * (i + 1) - 1, _chrPages[i]);
    }
  }

  void _updateNametableLayout(NametableLayout layout) {
    _nametableLayout = layout;
    nametableLayout = layout;
  }

  // registers 0x0-0x9 are identical on FCG-1/2 and LZ93D50; returns
  // whether the register was handled
  bool _writeCommonRegister(int register, int value) {
    switch (register) {
      case <= 7:
        _chrPages[register] = value;

        _updatePpuMapping();
      case 8:
        _prgPage = value;

        _updateCpuMapping();
      case 9:
        switch (value & 0x3) {
          case 0:
            _updateNametableLayout(.horizontal);
          case 1:
            _updateNametableLayout(.vertical);
          case 2:
            _updateNametableLayout(.singleLower);
          case 3:
            _updateNametableLayout(.singleUpper);
        }
      default:
        return false;
    }

    return true;
  }

  void _cpuWriteFcg1_2(int address, int value) {
    final register = address & 0xf;

    if (_writeCommonRegister(register, value)) {
      return;
    }

    switch (register) {
      case 0xa:
        _irqEnabled = (value & 1) == 1;

        bus.clearIrq(IrqSource.mapper);

        if (_irqEnabled && _irqCounter == 0) {
          bus.triggerIrq(IrqSource.mapper);
        }
      case 0xb:
        _irqCounter = (_irqCounter & 0xff00) | (value & 0xff);
      case 0xc:
        _irqCounter = ((value & 0xff) << 8) | (_irqCounter & 0xff);
      default:
        super.cpuWrite(address, value);
    }
  }

  void _cpuWriteLZ93D50(int address, int value) {
    final register = address & 0xf;

    if (_writeCommonRegister(register, value)) {
      return;
    }

    switch (register) {
      case 0xa:
        _irqEnabled = (value & 1) == 1;

        bus.clearIrq(IrqSource.mapper);

        if (_irqEnabled && _irqCounter == 0) {
          bus.triggerIrq(IrqSource.mapper);
        }

        _irqCounter = _irqLatch;
      case 0xb:
        _irqLatch = (_irqLatch & 0xff00) | (value & 0xff);
      case 0xc:
        _irqLatch = ((value & 0xff) << 8) | (_irqLatch & 0xff);
      case 0xd:
        final scl = value.bit(5);
        final sda = value.bit(6);

        _eeprom?.input(scl, sda);
      default:
        super.cpuWrite(address, value);
    }
  }
}
