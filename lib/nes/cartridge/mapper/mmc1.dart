import 'package:nes/extension/bit_extension.dart';
import 'package:nes/nes/bus.dart';
import 'package:nes/nes/cartridge/cartridge.dart';
import 'package:nes/nes/cartridge/mapper/mapper.dart';

class MMC1 extends Mapper {
  MMC1() : super(1);

  @override
  String name = 'MMC1';

  int shift = 0x10;

  int control = 0x0c;

  int get controlMirroring => control & 0x3;
  int get controlPrgMode => (control >> 2) & 0x3;
  int get controlChrMode => control.bit(4);

  int chrBank0 = 0;

  int chrBank1 = 1;

  int prgBank = 0;

  int get prgBankValue => prgBank & 0xf;
  int get prgBankRam => (prgBank >> 4) & 0x1;

  @override
  void reset() {
    final mirroring = switch (cartridge.nametableLayout) {
      NametableLayout.vertical => 3,
      NametableLayout.horizontal => 2,
      NametableLayout.four => 0,
      NametableLayout.single => 0,
    };

    shift = 0x10;
    control = 0x0c | mirroring;
    chrBank0 = 0;
    chrBank1 = 1;
    prgBank = 0;
  }

  @override
  int read(Bus bus, int address) {
    if (address < 0x2000) {
      return cartridge.chr[_chrAddress(address)];
    }

    if (address < 0x3f00) {
      return bus.ppu.ram[_nametableAddress(address & 0xfff)];
    }

    if (address < 0x6000) {
      return 0;
    }

    if (address < 0x8000) {
      return cartridge.sram[address & 0x1fff];
    }

    if (address <= 0xffff) {
      return cartridge.prgRom[_prgAddress(address & 0x7fff)];
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
      _writePpuRam(bus, address, value);

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

  void _writeChr(int address, int value) {
    if (cartridge.chrRomSize > 0) {
      // no CHR RAM -> not writable
      return;
    }

    cartridge.chr[_chrAddress(address)] = value;
  }

  void _writePpuRam(Bus bus, int address, int value) {
    bus.ppu.ram[_nametableAddress(address & 0xfff)] = value;
  }

  void _writeCartridgeSram(int address, int value) {
    cartridge.sram[address & 0x1fff] = value;
  }

  void _writeRegister(int address, int value) {
    // TODO ignore consecutive cycle writes
    if (value.bit(7) == 1) {
      shift = 0x10;
      control = control | 0xc;

      return;
    }

    if (shift.bit(0) == 1) {
      final register = (address >> 13) & 0x3;
      final registerValue = value.bit(0) << 4 | ((shift >> 1) & 0xf);

      shift = 0x10;

      switch (register) {
        case 0:
          control = registerValue;
        case 1:
          chrBank0 = registerValue;
        case 2:
          chrBank1 = registerValue;
        case 3:
          prgBank = registerValue;
      }

      return;
    }

    shift >>= 1;
    shift = shift.setBit(4, value.bit(0));
  }

  int _chrAddress(int address) {
    return switch (controlChrMode) {
          0 => ((chrBank0 & 0x1e) << 12) | (address & 0x1fff),
          1 => switch (address.bit(12)) {
              0 => (chrBank0 << 12) | (address & 0xfff),
              1 => (chrBank1 << 12) | (address & 0xfff),
              _ => 0,
            },
          _ => 0,
        } %
        cartridge.chr.length;
  }

  int _nametableAddress(int address) {
    return switch (controlMirroring) {
      0 => address & 0x3ff, // one-screen, lower bank
      1 => 0x400 | (address & 0x3ff), // one-screen, upper bank
      2 => address & 0x7ff, // vertical // TODO
      3 => (address & 0x7ff).setBit(10, address.bit(11)), // horizontal // TODO
      _ => 0,
    };
  }

  int _prgAddress(int address) {
    return switch (controlPrgMode) {
          // switchable 32k bank
          0 || 1 => ((prgBankValue & 0xe) << 14) | (address & 0x7fff),
          2 => switch (address.bit(14)) {
              // fixed first bank at 0x8000
              0 => address & 0x3fff,
              // switchable 16k bank at 0xc000
              1 => ((prgBankValue & 0xf) << 14) | (address & 0x3fff),
              _ => 0,
            },
          3 => switch (address.bit(14)) {
              // switchable 16k bank at 0x9000
              0 => ((prgBankValue & 0xf) << 14) | (address & 0x3fff),
              // fixed last bank at 0xc000
              1 => (cartridge.prgRomSize - 0x4000) | (address & 0x3fff),
              _ => 0,
            },
          _ => 0,
        } %
        cartridge.prgRomSize;
  }
}
