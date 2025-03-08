import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/mmc3_state.dart';
import 'package:nesd/nes/cpu/irq_source.dart';

class MMC3 extends Mapper {
  MMC3() : super(4);

  @override
  String name = 'MMC3';

  @override
  int prgRomPageSize = 0x2000;

  @override
  int chrPageSize = 0x0400;

  int _register = 0;
  int _r0 = 0;
  int _r1 = 0;
  int _r2 = 2;
  int _r3 = 3;
  int _r4 = 4;
  int _r5 = 5;
  int _r6 = 6;
  int _r7 = 1;

  int _prgBankMode = 0;

  int _chrBankMode = 0;

  int _mirroring = 0;

  int _irqCounter = 0;
  int _irqLatch = 0;

  bool _irqReload = false;
  bool _irqEnabled = false;

  int _a12LowStart = 0;

  @override
  MMC3State get state => MMC3State(
    register: _register,
    r0: _r0,
    r1: _r1,
    r2: _r2,
    r3: _r3,
    r4: _r4,
    r5: _r5,
    r6: _r6,
    r7: _r7,
    prgBankMode: _prgBankMode,
    chrBankMode: _chrBankMode,
    mirroring: _mirroring,
    irqCounter: _irqCounter,
    irqLatch: _irqLatch,
    irqReload: _irqReload,
    irqEnabled: _irqEnabled,
    a12LowStart: _a12LowStart,
  );

  @override
  set state(covariant MMC3State state) {
    _register = state.register;
    _r0 = state.r0;
    _r1 = state.r1;
    _r2 = state.r2;
    _r3 = state.r3;
    _r4 = state.r4;
    _r5 = state.r5;
    _r6 = state.r6;
    _r7 = state.r7;
    _prgBankMode = state.prgBankMode;
    _chrBankMode = state.chrBankMode;
    _mirroring = state.mirroring;
    _irqCounter = state.irqCounter;
    _irqLatch = state.irqLatch;
    _irqReload = state.irqReload;
    _irqEnabled = state.irqEnabled;
    _a12LowStart = state.a12LowStart;

    _updateState();
  }

  @override
  void reset() {
    super.reset();

    _register = 0;
    _r0 = 0;
    _r1 = 0;
    _r2 = 0;
    _r3 = 0;
    _r4 = 0;
    _r5 = 0;
    _r6 = 0;
    _r7 = 0;

    _prgBankMode = 0;
    _chrBankMode = switch (bus.cartridge.nametableLayout) {
      NametableLayout.vertical => 1,
      NametableLayout.horizontal => 0,
      NametableLayout.four => 0,
      NametableLayout.singleUpper => 1,
      NametableLayout.singleLower => 1,
    };

    _mirroring = 0;

    _irqCounter = 0;
    _irqLatch = 0;

    _irqReload = false;
    _irqEnabled = false;

    _a12LowStart = 0;

    _updateState();
  }

  @override
  void updatePpuAddress(int address) {
    if (!_a12RisingEdgeDetected(address)) {
      return;
    }

    if (_irqCounter == 0 || _irqReload) {
      _irqCounter = _irqLatch;
    } else {
      _irqCounter--;
    }

    if (_irqCounter == 0 && _irqEnabled) {
      bus.triggerIrq(IrqSource.mapper);
    }

    _irqReload = false;
  }

  @override
  void cpuWrite(int address, int value) {
    super.cpuWrite(address, value);

    switch (address & 0xe001) {
      // bank select (0x8000 - 0x9ffe, even)
      case 0x8000:
        final previousPrgBankMode = _prgBankMode;
        final previousChrBankMode = _chrBankMode;

        _register = value & 0x7;
        _prgBankMode = value.bit(6);
        _chrBankMode = value.bit(7);

        if (_prgBankMode != previousPrgBankMode) {
          _updatePrgPages();
        }

        if (_chrBankMode != previousChrBankMode) {
          _updateChrPages();
        }
      // bank data (0x8001 - 0x9fff, odd)
      case 0x8001:
        switch (_register) {
          case 0:
            _r0 = value & 0xfe;
            _updateChrPages();
          case 1:
            _r1 = value & 0xfe;
            _updateChrPages();
          case 2:
            _r2 = value;
            _updateChrPages();
          case 3:
            _r3 = value;
            _updateChrPages();
          case 4:
            _r4 = value;
            _updateChrPages();
          case 5:
            _r5 = value;
            _updateChrPages();
          case 6:
            _r6 = value & 0x3f;
            _updatePrgPages();
          case 7:
            _r7 = value & 0x3f;
            _updatePrgPages();
        }

      // Mirroring (0xa000 - 0xbffe, even)
      case 0xa000:
        _mirroring = value & 0x1;
        _updateMirroring();
      // PRG RAM protect (0xa001 - 0xbfff, odd)
      case 0xa001:
      // not implemented for compatibility with MMC6
      // IRQ latch (0xc000 - 0xdffe, even)
      case 0xc000:
        _irqLatch = value;
      // IRQ reload (0xc001 - 0xdfff, odd)
      case 0xc001:
        _irqCounter = 0;
        _irqReload = true;
      // IRQ disable (0xe000 - 0xfffe, even)
      case 0xe000:
        _irqEnabled = false;
        bus.clearIrq(IrqSource.mapper);
      // IRQ enable (0xe001 - 0xffff, odd)
      case 0xe001:
        _irqEnabled = true;
    }
  }

  void _updateState() {
    _updatePrgPages();
    _updateChrPages();
    _updateMirroring();
  }

  void _updatePrgPages() {
    switch (_prgBankMode) {
      case 0:
        mapCpu(0x8000, 0x9fff, _r6);
        mapCpu(0xa000, 0xbfff, _r7);
        mapCpu(0xc000, 0xdfff, -2);
        mapCpu(0xe000, 0xffff, -1);
      case 1:
        mapCpu(0x8000, 0x9fff, -2);
        mapCpu(0xa000, 0xbfff, _r7);
        mapCpu(0xc000, 0xdfff, _r6);
        mapCpu(0xe000, 0xffff, -1);
    }
  }

  void _updateChrPages() {
    switch (_chrBankMode) {
      case 0:
        mapPpu(0x0000, 0x07ff, _r0);
        mapPpu(0x0800, 0x0fff, _r1);
        mapPpu(0x1000, 0x13ff, _r2);
        mapPpu(0x1400, 0x17ff, _r3);
        mapPpu(0x1800, 0x1bff, _r4);
        mapPpu(0x1c00, 0x1fff, _r5);
      case 1:
        mapPpu(0x0000, 0x03ff, _r2);
        mapPpu(0x0400, 0x07ff, _r3);
        mapPpu(0x0800, 0x0bff, _r4);
        mapPpu(0x0c00, 0x0fff, _r5);
        mapPpu(0x1000, 0x17ff, _r0);
        mapPpu(0x1800, 0x1fff, _r1);
    }
  }

  void _updateMirroring() {
    nametableLayout = switch (_mirroring) {
      0 => NametableLayout.horizontal,
      1 => NametableLayout.vertical,
      _ => NametableLayout.horizontal,
    };
  }

  bool _a12RisingEdgeDetected(int address) {
    if (address.bit(12) == 1) {
      // rising edge only counts if A12 was low for at least 3 cycles
      final cyclesHaveElapsed =
          _a12LowStart > 0 && (bus.cpu.cycles - _a12LowStart) >= 3;

      _a12LowStart = 0;

      return cyclesHaveElapsed;
    }

    if (_a12LowStart == 0) {
      _a12LowStart = bus.cpu.cycles;
    }

    return false;
  }
}
