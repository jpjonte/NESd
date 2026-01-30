import 'dart:math';
import 'dart:typed_data';

import 'package:nesd/nes/cartridge/cartridge_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

enum NametableLayout { horizontal, vertical, four, singleUpper, singleLower }

enum RomFormat { iNes, nes20 }

enum ConsoleType { nes, vsSystem, extended }

enum TvSystem { ntsc, pal }

class Cartridge {
  Cartridge({
    required this.file,
    required this.rom,
    required this.prgRom,
    required this.chrRom,
    required this.chrRam,
    required this.prgRam,
    required this.prgSaveRam,
    required this.nametableLayout,
    required this.alternativeNametableLayout,
    required this.hasBattery,
    required this.hasTrainer,
    required this.mapper,
    required this.consoleType,
    required this.romFormat,
    required this.tvSystem,
    required this.fileHash,
    required this.romHash,
    required this.chrHash,
    required this.prgHash,
  }) {
    mapper.cartridge = this;
  }

  final FilesystemFile file;
  final Uint8List rom;
  final Uint8List prgRom;
  final Uint8List chrRom;
  final Uint8List chrRam;
  final Uint8List prgRam;
  final Uint8List prgSaveRam;
  final NametableLayout nametableLayout;
  final bool alternativeNametableLayout;
  final bool hasBattery;
  final bool hasTrainer;
  final Mapper mapper;
  final ConsoleType consoleType;
  final RomFormat romFormat;
  final TvSystem tvSystem;
  final String fileHash;
  final String romHash;
  final String chrHash;
  final String prgHash;

  late final NesDatabaseEntry? databaseEntry;

  CartridgeState get state => CartridgeState(
    prgRam: prgRam,
    prgSaveRam: prgSaveRam,
    chrRam: chrRam,
    mapperId: mapper.id,
    mapperState: mapper.state,
  );

  set state(CartridgeState state) {
    prgRam.setRange(0, min(prgRam.length, state.prgRam.length), state.prgRam);
    prgSaveRam.setRange(
      0,
      min(prgSaveRam.length, state.prgSaveRam.length),
      state.prgSaveRam,
    );
    chrRam.setRange(0, min(chrRam.length, state.chrRam.length), state.chrRam);

    mapper.state = state.mapperState;
  }

  RomInfo get romInfo => RomInfo(
    file: file,
    hash: fileHash,
    romHash: romHash,
    chrHash: chrHash,
    prgHash: prgHash,
  );

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

    return prgSaveRam;
  }

  void load(Uint8List save) {
    if (!hasBattery) {
      return;
    }

    prgSaveRam.setAll(0, prgSaveRam);
  }
}
