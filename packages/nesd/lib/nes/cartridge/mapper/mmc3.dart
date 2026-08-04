import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/mmc3_state.dart';
import 'package:nesd/nes/cpu/irq_source.dart';

class MMC3 extends Mapper {
  MMC3([super.id = 4, super.subMapperId = 0]);

  @override
  String name = 'MMC3';

  @override
  int prgRomPageSize = 0x2000;

  @override
  int chrPageSize = 0x0400;

  int get registerAddressMask => 0xe001;

  int get bankSelectMask => 0x07;

  int bankWriteMask(int register) => switch (register) {
    0 || 1 => 0xfe,
    6 || 7 => 0x3f,
    _ => 0xff,
  };

  bool isPrgBankRegister(int register) => register >= 6;

  PpuMemoryType? get chrMemoryType => null;

  int register = 0;

  final List<int> banks = List.filled(12, 0);

  int prgBankMode = 0;

  int chrBankMode = 0;

  int _mirroring = 0;

  int _irqCounter = 0;
  int _irqLatch = 0;

  bool _irqReload = false;
  bool _irqEnabled = false;

  int _a12LowStart = 0;

  @override
  MMC3State get state => MMC3State(
    register: register,
    r0: banks[0],
    r1: banks[1],
    r2: banks[2],
    r3: banks[3],
    r4: banks[4],
    r5: banks[5],
    r6: banks[6],
    r7: banks[7],
    prgBankMode: prgBankMode,
    chrBankMode: chrBankMode,
    mirroring: _mirroring,
    irqCounter: _irqCounter,
    irqLatch: _irqLatch,
    irqReload: _irqReload,
    irqEnabled: _irqEnabled,
    a12LowStart: _a12LowStart,
  );

  @override
  set state(covariant MMC3State state) {
    register = state.register;

    banks
      ..[0] = state.r0
      ..[1] = state.r1
      ..[2] = state.r2
      ..[3] = state.r3
      ..[4] = state.r4
      ..[5] = state.r5
      ..[6] = state.r6
      ..[7] = state.r7;

    prgBankMode = state.prgBankMode;
    chrBankMode = state.chrBankMode;
    _mirroring = state.mirroring;
    _irqCounter = state.irqCounter;
    _irqLatch = state.irqLatch;
    _irqReload = state.irqReload;
    _irqEnabled = state.irqEnabled;
    _a12LowStart = state.a12LowStart;

    _remapAll();
  }

  @override
  void reset() {
    super.reset();

    register = 0;
    banks.fillRange(0, banks.length, 0);

    prgBankMode = 0;
    chrBankMode = switch (bus.cartridge.nametableLayout) {
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

    _remapAll();
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
  bool get needsPpuAddressUpdates => true;

  @override
  void cpuWrite(int address, int value) {
    super.cpuWrite(address, value);

    switch (address & registerAddressMask) {
      // bank select (0x8000 - 0x9ffe, even)
      case 0x8000:
        final previousPrgBankMode = prgBankMode;
        final previousChrBankMode = chrBankMode;

        register = value & bankSelectMask;
        prgBankMode = value.bit(6);
        chrBankMode = value.bit(7);

        if (prgBankMode != previousPrgBankMode) {
          updatePrgPages();
        }

        if (chrBankMode != previousChrBankMode) {
          updateChrPages();
        }

      // bank data (0x8001 - 0x9fff, odd)
      case 0x8001:
        banks[register] = value & bankWriteMask(register);

        if (isPrgBankRegister(register)) {
          updatePrgPages();
        } else {
          updateChrPages();
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

  void _remapAll() {
    updatePrgPages();
    updateChrPages();
    _updateMirroring();
  }

  int prgPage(int slot) => switch (prgBankMode) {
    0 => switch (slot) {
      0 => banks[6],
      1 => banks[7],
      2 => -2,
      _ => -1,
    },
    _ => switch (slot) {
      0 => -2,
      1 => banks[7],
      2 => banks[6],
      _ => -1,
    },
  };

  int chrPage(int slot) => switch (chrBankMode) {
    0 => switch (slot) {
      0 => banks[0],
      1 => banks[0] + 1,
      2 => banks[1],
      3 => banks[1] + 1,
      _ => banks[slot - 2],
    },
    _ => switch (slot) {
      0 || 1 || 2 || 3 => banks[slot + 2],
      4 => banks[0],
      5 => banks[0] + 1,
      6 => banks[1],
      _ => banks[1] + 1,
    },
  };

  void updatePrgPages() {
    for (var slot = 0; slot < 4; slot++) {
      final address = 0x8000 + slot * 0x2000;

      mapCpu(address, address + 0x1fff, prgPage(slot));
    }
  }

  void updateChrPages() {
    for (var slot = 0; slot < 8; slot++) {
      final address = slot * 0x400;

      mapPpu(address, address + 0x3ff, chrPage(slot), type: chrMemoryType);
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
