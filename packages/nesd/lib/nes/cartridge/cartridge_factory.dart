import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:nesd/exception/invalid_rom_header.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cartridge_factory.g.dart';

class CartridgeFactory {
  const CartridgeFactory({required this.database});

  final NesDatabase database;

  Cartridge fromFile(FilesystemFile file, Uint8List rom) {
    if (rom[0] != 0x4E || rom[1] != 0x45 || rom[2] != 0x53 || rom[3] != 0x1A) {
      throw InvalidRomHeader(rom.sublist(0, 4));
    }

    final chr = _parseChr(rom);
    final prgRom = _parsePrgRom(rom);

    final romHash = sha1.convert(rom.sublist(16)).toString();
    final prgHash = sha1.convert(prgRom).toString();

    final databaseEntry = database.find(
      RomInfo(file: file, romHash: romHash, prgHash: prgHash),
    );

    final romFormat = _parseRomFormat(rom);

    final prgRamSize =
        databaseEntry?.prgRamSize ?? _parsePrgRamSize(rom, romFormat);
    final prgSaveRamSize =
        databaseEntry?.prgSaveRamSize ?? _parsePrgSaveRamSize(rom, romFormat);
    final chrRamSize =
        databaseEntry?.chrRamSize ?? _parseChrRamSize(rom, romFormat);

    final hasBattery = databaseEntry?.hasBattery ?? _parseHasBattery(rom);

    final mapperId = _parseMapperId(rom, romFormat, databaseEntry);
    final subMapperId = _parseSubMapperId(rom, romFormat, databaseEntry);

    final mapper = Mapper.fromId(mapperId, subMapperId, prgSaveRamSize);

    return Cartridge(
      file: file,
      rom: rom,
      prgRom: prgRom,
      chrRom: chr,
      chrRam: Uint8List(chrRamSize),
      prgRam: Uint8List(prgRamSize),
      prgSaveRam: Uint8List(prgSaveRamSize),
      nametableLayout: _parseNametableLayout(rom),
      alternativeNametableLayout: _parseAlternativeNametableLayout(rom),
      hasBattery: hasBattery,
      hasTrainer: _parseHasTrainer(rom),
      mapper: mapper,
      consoleType: _parseConsoleType(rom),
      romFormat: romFormat,
      tvSystem: _parseTvSystem(rom),
      fileHash: sha1.convert(rom).toString(),
      romHash: romHash,
      chrHash: sha1.convert(chr).toString(),
      prgHash: prgHash,
    );
  }

  Uint8List _parsePrgRom(Uint8List rom) {
    final trainerSize = (rom[6] & 0x04) != 0 ? 512 : 0;
    final prgRomSize = rom[4] * 0x4000;

    return rom.sublist(16 + trainerSize, 16 + trainerSize + prgRomSize);
  }

  Uint8List _parseChr(Uint8List rom) {
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

  NametableLayout _parseNametableLayout(Uint8List rom) {
    return (rom[6] & 0x01) == 0
        ? NametableLayout.vertical
        : NametableLayout.horizontal;
  }

  bool _parseAlternativeNametableLayout(Uint8List rom) {
    return (rom[6] & 0x08) != 0;
  }

  bool _parseHasBattery(Uint8List rom) {
    return (rom[6] & 0x02) != 0;
  }

  bool _parseHasTrainer(Uint8List rom) {
    return (rom[6] & 0x04) != 0;
  }

  int _parseMapperId(
    Uint8List rom,
    RomFormat romFormat,
    NesDatabaseEntry? databaseEntry,
  ) {
    final flags6 = rom[6];
    final flags7 = rom[7];
    final flags8 = rom[8];

    var mapperId = (flags7 & 0xf0) | ((flags6 & 0xf0) >> 4);

    if (romFormat == .nes20) {
      mapperId = ((flags8 & 0x0f) << 8) | mapperId;
    }

    return databaseEntry?.mapper ?? mapperId;
  }

  int _parseSubMapperId(
    Uint8List rom,
    RomFormat romFormat,
    NesDatabaseEntry? databaseEntry,
  ) {
    final flags8 = rom[8];

    var subMapperId = 0;

    if (romFormat == .nes20) {
      subMapperId = (flags8 & 0xf0) >> 4;
    }

    return databaseEntry?.submapper ?? subMapperId;
  }

  ConsoleType _parseConsoleType(Uint8List rom) {
    return ConsoleType.values[rom[7] & 0x03];
  }

  int _parsePrgRamSize(Uint8List rom, RomFormat romFormat) {
    if (romFormat == .iNes) {
      return max(1, rom[8]) * 0x2000;
    } else {
      return 0;
    }
  }

  int _parsePrgSaveRamSize(Uint8List rom, RomFormat romFormat) {
    if (romFormat == .iNes) {
      return 0x2000;
    } else {
      return 0;
    }
  }

  int _parseChrRamSize(Uint8List rom, RomFormat romFormat) {
    if (romFormat == .iNes) {
      final chrRomSize = rom[5] * 0x2000;

      // iNES 1.0 has no CHR-RAM size field; boards with 0 CHR-ROM banks
      // default to the standard 8KB CHR RAM.
      return chrRomSize == 0 ? 0x2000 : 0;
    } else {
      return 64 << (rom[11] & 0x0f);
    }
  }

  TvSystem _parseTvSystem(Uint8List rom) {
    final v = rom[9] & 0x03;
    // iNES header stores TV system but values 2/3 are reserved/unknown.
    // Default unknowns to NTSC for stability in tools/tests.
    switch (v) {
      case 0:
        return TvSystem.ntsc;
      case 1:
        return TvSystem.pal;
      default:
        return TvSystem.ntsc;
    }
  }

  RomFormat _parseRomFormat(Uint8List rom) {
    return (rom[7] & 0x0C) == 0x08 ? RomFormat.nes20 : RomFormat.iNes;
  }
}

@riverpod
CartridgeFactory cartridgeFactory(Ref ref) =>
    CartridgeFactory(database: ref.watch(databaseProvider));
