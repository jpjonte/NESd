import 'package:nes/extension/bit_extension.dart';
import 'package:nes/nes/bus.dart';
import 'package:nes/nes/cartridge/cartridge.dart';
import 'package:nes/nes/cartridge/mapper/mapper.dart';
import 'package:nes/nes/cartridge/mapper/mmc3_state.dart';

class MMC3 extends Mapper {
  MMC3() : super(4);

  @override
  String name = 'MMC3';

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
  }

  @override
  void reset() {
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
    _chrBankMode = switch (bus.cartridge?.nametableLayout) {
      NametableLayout.vertical => 1,
      NametableLayout.horizontal => 0,
      NametableLayout.four => 0,
      NametableLayout.single => 1,
      null => 0,
    };

    _mirroring = 0;

    _irqCounter = 0;
    _irqLatch = 0;

    _irqReload = false;
    _irqEnabled = false;

    _a12LowStart = 0;
  }

  @override
  int read(Bus bus, int address) {
    if (address < 0x2000) {
      final chrAddress = _chrAddress(address);
      final chrValue = cartridge.chr[chrAddress];

      return chrValue;
    }

    if (address < 0x3f00) {
      final ntAddress = _nametableAddress(address & 0xfff);

      final value = bus.ppu.ram[ntAddress];

      return value;
    }

    if (address < 0x6000) {
      return 0;
    }

    if (address < 0x8000) {
      return cartridge.sram[address & 0x1fff];
    }

    if (address <= 0xffff) {
      return cartridge.prgRom[_prgAddress(address)];
    }

    return 0;
  }

  @override
  void write(Bus bus, int address, int value) {
    if (address < 0x2000) {
      _writeChr(address, value);

      return;
    }

    if (address < 0x3f00) {
      _writePpuRam(address, value);

      return;
    }

    if (address < 0x6000) {
      return;
    }

    if (address < 0x8000) {
      _writeCartridgeSram(address, value);

      return;
    }

    if (address <= 0xffff) {
      _writeRegister(address, value);
    }
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
      bus.triggerIrq();
    }

    _irqReload = false;
  }

  void _writeChr(int address, int value) {
    if (cartridge.chrRomSize > 0) {
      // no CHR RAM -> not writable
      return;
    }

    cartridge.chr[_chrAddress(address)] = value;
  }

  void _writePpuRam(int address, int value) {
    bus.ppu.ram[_nametableAddress(address & 0xfff)] = value;
  }

  void _writeCartridgeSram(int address, int value) {
    cartridge.sram[address & 0x1fff] = value;
  }

  void _writeRegister(int address, int value) {
    switch (address & 0xe001) {
      // bank select (0x8000 - 0x9ffe, even)
      case 0x8000:
        _register = value & 0x7;
        _prgBankMode = value.bit(6);
        _chrBankMode = value.bit(7);
      // bank data (0x8001 - 0x9fff, odd)
      case 0x8001:
        switch (_register) {
          case 0:
            _r0 = value & 0xfe;
          case 1:
            _r1 = value & 0xfe;
          case 2:
            _r2 = value;
          case 3:
            _r3 = value;
          case 4:
            _r4 = value;
          case 5:
            _r5 = value;
          case 6:
            _r6 = value & 0x3f;
          case 7:
            _r7 = value & 0x3f;
        }
      // Mirroring (0xa000 - 0xbffe, even)
      case 0xa000:
        _mirroring = value & 0x1;
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
        bus.acknowledgeIrq();
      // IRQ enable (0xe001 - 0xffff, odd)
      case 0xe001:
        _irqEnabled = true;
    }
  }

  int _chrAddress(int address) {
    return switch (_chrBankMode) {
      0 => switch (address >> 10) {
          // 0x0000 - 0x07ff -> r0 (2k)
          0 || 1 => _r0 << 10 | address & 0x7ff,
          // 0x0800 - 0x0fff -> r1 (2k)
          2 || 3 => _r1 << 10 | address & 0x7ff,
          // 0x1000 - 0x13ff -> r2 (1k)
          4 => _r2 << 10 | address & 0x3ff,
          // 0x1400 - 0x17ff -> r3 (1k)
          5 => _r3 << 10 | address & 0x3ff,
          // 0x1800 - 0x1bff -> r4 (1k)
          6 => _r4 << 10 | address & 0x3ff,
          // 0x1c00 - 0x1fff -> r5 (1k)
          7 => _r5 << 10 | address & 0x3ff,
          _ => 0,
        },
      1 => switch (address >> 10) {
          // 0x0000 - 0x03ff -> r2 (1k)
          0 => _r2 << 10 | address & 0x3ff,
          // 0x0400 - 0x07ff -> r3 (1k)
          1 => _r3 << 10 | address & 0x3ff,
          // 0x0800 - 0x0bff -> r4 (1k)
          2 => _r4 << 10 | address & 0x3ff,
          // 0x0c00 - 0x0fff -> r5 (1k)
          3 => _r5 << 10 | address & 0x3ff,
          // 0x1000 - 0x17ff -> r0 (2k)
          4 || 5 => _r0 << 10 | address & 0x7ff,
          // 0x1800 - 0x1fff -> r1 (2k)
          6 || 7 => _r1 << 10 | address & 0x7ff,
          _ => 0,
        },
      _ => 0,
    };
  }

  int _nametableAddress(int address) {
    return switch (_mirroring) {
      0 => switch (address) {
          < 0x0400 => address,
          < 0x0800 => address,
          < 0x0c00 => address - 0x800,
          < 0x1000 => address - 0x800,
          _ => 0,
        }, // address & 0x7ff, // vertical
      1 => switch (address) {
          < 0x0400 => address,
          < 0x0800 => address - 0x400,
          < 0x0c00 => address - 0x400,
          < 0x1000 => address - 0x800,
          _ => 0,
        }, //(address & 0x7ff).setBit(10, address.bit(11)), // horizontal
      _ => 0,
    };
  }

  int _prgAddress(int address) {
    return switch (_prgBankMode) {
      0 => switch (address & 0xe000) {
          // 0x8000 - 0x9fff -> r6
          0x8000 => _r6 << 13 | address & 0x1fff,
          // 0xa000 - 0xbfff -> r7
          0xa000 => _r7 << 13 | address & 0x1fff,
          // 0xc000 - 0xffff -> starting from second to last bank
          0xc000 ||
          0xe000 =>
            (cartridge.prgRom.length - 0x4000) | address & 0x3fff,
          _ => 0,
        },
      1 => switch ((address >> 13) & 0x3) {
          // 0x8000 - 0x9fff -> second to last bank
          0 => (cartridge.prgRom.length - 0x4000) | address & 0x1fff,
          // 0xa000 - 0xbfff -> r7
          1 => _r7 << 13 | address & 0x1fff,
          // 0xc000 - 0xdfff -> r6
          2 => _r6 << 13 | address & 0x1fff,
          // 0xe000 - 0xffff -> last bank
          3 => (cartridge.prgRom.length - 0x2000) | address & 0x1fff,
          _ => 0,
        },
      _ => 0,
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
