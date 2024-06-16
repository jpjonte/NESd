import 'package:nes/extension/bit_extension.dart';
import 'package:nes/nes/bus.dart';
import 'package:nes/nes/cartridge/mapper/mapper.dart';

class AxROM extends Mapper {
  AxROM() : super(7);

  int prgBank = 0;

  int chrBank = 0;

  @override
  String name = 'AxROM';

  @override
  void reset() {
    prgBank = 0;
    chrBank = 0;
  }

  @override
  int read(Bus bus, int address) {
    if (address < 0x2000) {
      return cartridge.chr[_chrAddress(address)];
    }

    if (address < 0x3f00) {
      return bus.ppu.ram[_nametableAddress(address)];
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
      prgBank = value & 0x07;
      chrBank = value.bit(4);
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
    bus.ppu.ram[_nametableAddress(address)] = value;
  }

  void _writeCartridgeSram(int address, int value) {
    cartridge.sram[address & 0x1fff] = value;
  }

  int _chrAddress(int address) {
    return address % cartridge.chr.length;
  }

  int _nametableAddress(int address) {
    return chrBank << 10 | address & 0x3ff;
  }

  int _prgAddress(int address) {
    return prgBank << 15 | address & 0x7fff;
  }
}
