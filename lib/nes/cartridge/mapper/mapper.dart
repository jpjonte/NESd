import 'package:nes/exception/unsupported_mapper.dart';
import 'package:nes/extension/bit_extension.dart';
import 'package:nes/nes/bus.dart';
import 'package:nes/nes/cartridge/cartridge.dart';
import 'package:nes/nes/cartridge/mapper/mmc1.dart';
import 'package:nes/nes/cartridge/mapper/nrom.dart';

abstract class Mapper {
  Mapper(this.id);

  factory Mapper.fromId(int mapper) {
    return switch (mapper) {
      0 => NROM(),
      1 => MMC1(),
      _ => throw UnsupportedMapper(mapper),
    };
  }

  final int id;

  late final Cartridge cartridge;

  String get name;

  void reset() {}

  int read(Bus bus, int address);

  void write(Bus bus, int address, int value);

  int nametableMirror(int address) {
    return switch (cartridge.nametableLayout) {
      NametableLayout.vertical =>
        (address & 0xfff).setBit(10, address.bit(11)).setBit(11, 0),
      NametableLayout.horizontal => address & 0x7ff,
      NametableLayout.four => address & 0xfff,
      NametableLayout.single => address & 0x3ff,
    };
  }
}