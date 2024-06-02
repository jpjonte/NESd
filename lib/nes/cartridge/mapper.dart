import 'package:nes/exception/unsupported_mapper.dart';
import 'package:nes/extension/bit_extension.dart';
import 'package:nes/nes/bus.dart';
import 'package:nes/nes/cartridge/cartridge.dart';

abstract class Mapper {
  factory Mapper(int mapper, int subMapper) {
    switch (mapper) {
      case 0:
        return Mapper0();
      default:
        throw UnsupportedMapper(mapper, subMapper);
    }
  }

  Mapper._();

  String get name;

  int read(Bus bus, Cartridge cartridge, int address);

  void write(Bus bus, Cartridge cartridge, int address, int value);

  int _nametableMirror(Cartridge cartridge, int address) {
    return switch (cartridge.nametableLayout) {
      NametableLayout.vertical =>
        (address & 0xfff).setBit(10, address.bit(11)).setBit(11, 0),
      NametableLayout.horizontal => address & 0x7ff,
      NametableLayout.four => address & 0xfff,
      NametableLayout.single => address & 0x3ff,
    };
  }
}

class Mapper0 extends Mapper {
  Mapper0() : super._();

  @override
  String name = 'NROM';

  @override
  int read(Bus bus, Cartridge cartridge, int address) {
    if (address < 0x2000) {
      return cartridge.chrRom[address];
    }

    if (address < 0x3f00) {
      return bus.ppu.ram[_nametableMirror(cartridge, address)];
    }

    if (address < 0x6000) {
      return 0;
    }

    if (address < 0x8000) {
      if (!cartridge.hasBattery) {
        return 0;
      }

      return cartridge.sram[address - 0x6000];
    }

    if (address <= 0xffff) {
      return cartridge.prgRom[address % cartridge.prgRomSize];
    }

    return 0;
  }

  @override
  void write(Bus bus, Cartridge cartridge, int address, int value) {
    if (address < 0x2000) {
      return;
    }

    if (address < 0x3f00) {
      bus.ppu.ram[_nametableMirror(cartridge, address)] = value;

      return;
    }
  }
}
