import 'package:nes/exception/unsupported_mapper.dart';
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

  void write(Cartridge cartridge, int address, int value);
  int read(Cartridge cartridge, int address);
}

class Mapper0 extends Mapper {
  Mapper0() : super._();

  @override
  String name = 'NROM';

  @override
  void write(Cartridge cartridge, int address, int value) {}

  @override
  int read(Cartridge cartridge, int address) {
    if (address < 0x2000) {
      return cartridge.chrRom[address];
    }

    if (address >= 0x8000) {
      return cartridge.prgRom[address % cartridge.prgRomSize];
    }

    if (address >= 0x6000) {
      if (!cartridge.hasBattery) {
        return 0;
      }

      return cartridge.sram[address - 0x6000];
    }

    return 0;
  }
}
