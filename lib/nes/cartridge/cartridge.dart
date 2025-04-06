import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:nesd/exception/invalid_rom_header.dart';
import 'package:nesd/nes/cartridge/cartridge_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:path/path.dart' as p;

enum NametableLayout { horizontal, vertical, four, singleUpper, singleLower }

enum RomFormat { iNes, nes20 }

enum ConsoleType { nes, vsSystem, extended }

enum TvSystem { ntsc, pal }

class Cartridge {
  Cartridge._internal({
    required this.file,
    required this.rom,
    required this.prgRom,
    required this.chr,
    required this.prgRomSize,
    required this.chrRomSize,
    required this.nametableLayout,
    required this.alternativeNametableLayout,
    required this.hasBattery,
    required this.hasTrainer,
    required this.mapper,
    required this.consoleType,
    required this.romFormat,
    required this.prgRamSize,
    required this.tvSystem,
    required this.fileHash,
    required this.romHash,
    required this.chrHash,
    required this.prgHash,
  }) {
    mapper.cartridge = this;
  }

  factory Cartridge.fromFile(String path, Uint8List rom) {
    if (rom[0] != 0x4E || rom[1] != 0x45 || rom[2] != 0x53 || rom[3] != 0x1A) {
      throw InvalidRomHeader(rom.sublist(0, 4));
    }

    final chr = _parseChr(rom);
    final prg = _parsePrgRom(rom);

    return Cartridge._internal(
      file: path,
      rom: rom,
      prgRom: prg,
      chr: chr,
      prgRomSize: _parsePrgRomSize(rom),
      chrRomSize: _parseChrRomSize(rom),
      nametableLayout: _parseNametableLayout(rom),
      alternativeNametableLayout: _parseAlternativeNametableLayout(rom),
      hasBattery: _parseHasBattery(rom),
      hasTrainer: _parseHasTrainer(rom),
      mapper: _parseMapper(rom),
      consoleType: _parseConsoleType(rom),
      romFormat: _parseRomFormat(rom),
      prgRamSize: _parsePrgRamSize(rom),
      tvSystem: _parseTvSystem(rom),
      fileHash: sha1.convert(rom).toString(),
      romHash: sha1.convert(rom.sublist(16)).toString(),
      chrHash: sha1.convert(chr).toString(),
      prgHash: sha1.convert(prg).toString(),
    );
  }

  final String file;
  final Uint8List rom;
  final Uint8List prgRom;
  final Uint8List chr;
  final int prgRomSize;
  final int chrRomSize;
  final NametableLayout nametableLayout;
  final bool alternativeNametableLayout;
  final bool hasBattery;
  final bool hasTrainer;
  final Mapper mapper;
  final ConsoleType consoleType;
  final RomFormat romFormat;
  final int prgRamSize;
  final TvSystem tvSystem;
  final String fileHash;
  final String romHash;
  final String chrHash;
  final String prgHash;

  late final NesDatabaseEntry? databaseEntry;

  final Uint8List sram = Uint8List(0x10000);

  CartridgeState get state => CartridgeState(
    chr: chr,
    sram: sram,
    mapperId: mapper.id,
    mapperState: mapper.state,
  );

  set state(CartridgeState state) {
    if (chrRomSize == 0) {
      chr.setAll(0, state.chr);
    }

    sram.setAll(0, state.sram);
    mapper.state = state.mapperState;
  }

  RomInfo get romInfo => RomInfo(
    name: p.basename(file),
    path: file,
    hash: fileHash,
    romHash: romHash,
    chrHash: chrHash,
    prgHash: prgHash,
  );

  static Uint8List _parsePrgRom(Uint8List rom) {
    final trainerSize = (rom[6] & 0x04) != 0 ? 512 : 0;
    final prgRomSize = rom[4] * 0x4000;

    return rom.sublist(16 + trainerSize, 16 + trainerSize + prgRomSize);
  }

  static Uint8List _parseChr(Uint8List rom) {
    final trainerSize = (rom[6] & 0x04) != 0 ? 512 : 0;
    final prgRomSize = rom[4] * 0x4000;
    final chrRomSize = rom[5] * 0x2000;

    if (chrRomSize == 0) {
      return Uint8List(0x10000);
    }

    return rom.sublist(
      16 + trainerSize + prgRomSize,
      16 + trainerSize + prgRomSize + chrRomSize,
    );
  }

  static int _parsePrgRomSize(Uint8List rom) {
    return rom[4] * 0x4000;
  }

  static int _parseChrRomSize(Uint8List rom) {
    return rom[5] * 0x2000;
  }

  static NametableLayout _parseNametableLayout(Uint8List rom) {
    return (rom[6] & 0x01) == 0
        ? NametableLayout.vertical
        : NametableLayout.horizontal;
  }

  static bool _parseAlternativeNametableLayout(Uint8List rom) {
    return (rom[6] & 0x08) != 0;
  }

  static bool _parseHasBattery(Uint8List rom) {
    return (rom[6] & 0x02) != 0;
  }

  static bool _parseHasTrainer(Uint8List rom) {
    return (rom[6] & 0x04) != 0;
  }

  static Mapper _parseMapper(Uint8List rom) {
    final flags6 = rom[6];
    final flags7 = rom[7];
    final flags8 = rom[8];

    late int mapperId;

    if (_parseRomFormat(rom) == RomFormat.nes20) {
      mapperId =
          ((flags8 & 0xF0) << 4) | (flags7 & 0xF0) | ((flags6 & 0xF0) >> 4);
    } else {
      mapperId = (flags7 & 0xF0) | ((flags6 & 0xF0) >> 4);
    }

    return Mapper.fromId(mapperId);
  }

  static ConsoleType _parseConsoleType(Uint8List rom) {
    return ConsoleType.values[rom[7] & 0x03];
  }

  static RomFormat _parseRomFormat(Uint8List rom) {
    return (rom[7] & 0x0C) == 0x08 ? RomFormat.nes20 : RomFormat.iNes;
  }

  static int _parsePrgRamSize(Uint8List rom) {
    final flags8 = rom[8];
    if (_parseRomFormat(rom) == RomFormat.iNes) {
      return flags8 * 0x2000;
    } else {
      return 0;
    }
  }

  static TvSystem _parseTvSystem(Uint8List rom) {
    return TvSystem.values[rom[9] & 0x03];
  }

  void reset() {
    mapper.reset();
  }

  void step() {
    mapper.step();
  }

  int cpuRead(int address, {bool disableSideEffects = false}) {
    return mapper.cpuRead(address, disableSideEffects: disableSideEffects);
  }

  int ppuRead(int address, {bool disableSideEffects = false}) {
    return mapper.ppuRead(address, disableSideEffects: disableSideEffects);
  }

  void cpuWrite(int address, int value) {
    mapper.cpuWrite(address, value);
  }

  void ppuWrite(int address, int value) {
    mapper.ppuWrite(address, value);
  }

  Uint8List? save() {
    if (!hasBattery) {
      return null;
    }

    return sram;
  }

  void load(Uint8List save) {
    if (!hasBattery) {
      return;
    }

    sram.setAll(0, save);
  }
}
