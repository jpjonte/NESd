import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/cartridge/mapper/cnrom_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';

class CNROM extends Mapper {
  CNROM() : super(3);

  int chrBank = 0;

  @override
  CNROMState get state => CNROMState(chrBank: chrBank);

  @override
  set state(covariant CNROMState state) {
    chrBank = state.chrBank;
  }

  @override
  String name = 'CNROM';

  @override
  void reset() {
    chrBank = 0;
  }

  @override
  int read(Bus bus, int address, {bool debug = false}) {
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
    if (address <= 0xffff) {
      return cartridge.prgRom[(address - 0x8000) % cartridge.prgRom.length];
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
      chrBank = value & 0x0f;
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
    return ((chrBank << 13) | (address & 0x1fff)) % cartridge.chr.length;
  }
}
