import 'package:nesd/exception/unsupported_mapper.dart';
import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/mapper/axrom.dart';
import 'package:nesd/nes/cartridge/mapper/br909x.dart';
import 'package:nesd/nes/cartridge/mapper/cnrom.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';
import 'package:nesd/nes/cartridge/mapper/mmc1.dart';
import 'package:nesd/nes/cartridge/mapper/mmc3.dart';
import 'package:nesd/nes/cartridge/mapper/nrom.dart';
import 'package:nesd/nes/cartridge/mapper/unrom.dart';

abstract class Mapper {
  Mapper(this.id);

  factory Mapper.fromId(int mapper) {
    return switch (mapper) {
      0 => NROM(),
      1 => MMC1(),
      2 => UNROM(),
      3 => CNROM(),
      4 => MMC3(),
      7 => AxROM(),
      71 => BR909x(),
      _ => throw UnsupportedMapper(mapper),
    };
  }

  final int id;

  late final Bus bus;

  late final Cartridge _cartridge;

  Cartridge get cartridge => _cartridge;

  set cartridge(Cartridge cartridge) {
    _cartridge = cartridge;
    nametableLayout = cartridge.nametableLayout;
  }

  late NametableLayout nametableLayout;

  MapperState get state;

  set state(MapperState state);

  String get name;

  void reset() {}

  int read(int address, {bool debug = false}) {
    if (address < 0x2000) {
      return readChr(address);
    }

    if (address < 0x3f00) {
      return readPpuRam(address);
    }

    if (address < 0x6000) {
      return 0;
    }

    if (address < 0x8000) {
      return readSram(address);
    }

    if (address <= 0xffff) {
      return readPrgRom(address);
    }

    return 0;
  }

  int readChr(int address) {
    if (cartridge.chr.isEmpty) {
      return 0;
    }

    return cartridge.chr[chrAddress(address)];
  }

  int readPpuRam(int address) => bus.ppu.ram[nametableAddress(address)];

  int readSram(int address) => cartridge.sram[address & 0x1fff];

  int readPrgRom(int address) => cartridge.prgRom[prgAddress(address)];

  int chrAddress(int address) {
    return address % cartridge.chr.length;
  }

  int nametableAddress(int address) {
    return switch (nametableLayout) {
      NametableLayout.vertical => (address & 0x7ff).setBit(10, address.bit(11)),
      NametableLayout.horizontal => address & 0x7ff,
      NametableLayout.four => address & 0xfff,
      NametableLayout.singleUpper => address & 0x3ff,
      NametableLayout.singleLower => 0x400 + address & 0x3ff,
    };
  }

  int prgAddress(int address) {
    return address % cartridge.prgRomSize;
  }

  void write(Bus bus, int address, int value) {
    if (address < 0x2000) {
      writeChr(address, value);

      return;
    }

    if (address < 0x3f00) {
      writePpuRam(address, value);

      return;
    }

    if (address < 0x6000) {
      return;
    }

    if (address < 0x8000) {
      writeCartridgeSram(address, value);

      return;
    }

    if (address <= 0xffff) {
      writePrg(address, value);
    }
  }

  void writeChr(int address, int value) {
    if (cartridge.chrRomSize > 0) {
      // no CHR RAM -> not writable
      return;
    }

    cartridge.chr[chrAddress(address)] = value;
  }

  void writePpuRam(int address, int value) {
    bus.ppu.ram[nametableAddress(address)] = value;
  }

  void writeCartridgeSram(int address, int value) {
    cartridge.sram[address & 0x1fff] = value;
  }

  void writePrg(int address, int value) {}

  void updatePpuAddress(int address) {}
}
