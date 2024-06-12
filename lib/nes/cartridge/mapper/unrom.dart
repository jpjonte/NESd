import 'package:nes/nes/bus.dart';
import 'package:nes/nes/cartridge/mapper/mapper.dart';

class UNROM extends Mapper {
  UNROM() : super(2);

  int prgBank = 0;

  @override
  String name = 'UNROM';

  @override
  void reset() {
    prgBank = 0;
  }

  @override
  int read(Bus bus, int address) {
    if (address < 0x2000) {
      return cartridge.chr[_chrAddress(address)];
    }

    if (address < 0x3f00) {
      return bus.ppu.ram[nametableMirror(address)];
    }

    if (address < 0x6000) {
      return 0;
    }

    if (address < 0x8000) {
      return cartridge.sram[address & 0x1fff];
    }

    if (address < 0xc000) {
      return cartridge.prgRom[((prgBank & 0xf) << 14) | (address & 0x3fff)];
    }

    if (address <= 0xffff) {
      return cartridge
          .prgRom[(cartridge.prgRomSize - 0x4000) | (address & 0x3fff)];
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
      prgBank = value & 0x0f;
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
    bus.ppu.ram[nametableMirror(address & 0xfff)] = value;
  }

  void _writeCartridgeSram(int address, int value) {
    cartridge.sram[address & 0x1fff] = value;
  }

  int _chrAddress(int address) {
    return address % cartridge.chr.length;
  }
}
