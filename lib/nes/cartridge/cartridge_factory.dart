import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final prgRamSize = databaseEntry?.prgRamSize ?? _parsePrgRamSize(rom);
    final prgSaveRamSize =
        databaseEntry?.prgSaveRamSize ?? _parsePrgSaveRamSize(rom);
    final chrRamSize = databaseEntry?.chrRamSize ?? _parseChrRamSize(rom);

    final hasBattery = databaseEntry?.hasBattery ?? _parseHasBattery(rom);

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
      mapper: _parseMapper(rom),
      consoleType: _parseConsoleType(rom),
      romFormat: _parseRomFormat(rom),
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

  Mapper _parseMapper(Uint8List rom) {
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

  ConsoleType _parseConsoleType(Uint8List rom) {
    return ConsoleType.values[rom[7] & 0x03];
  }

  int _parsePrgRamSize(Uint8List rom) {
    if (_parseRomFormat(rom) == RomFormat.iNes) {
      return max(1, rom[8]) * 0x2000;
    } else {
      return 0;
    }
  }

  int _parsePrgSaveRamSize(Uint8List rom) {
    if (_parseRomFormat(rom) == RomFormat.iNes) {
      return 0x2000;
    } else {
      return 0;
    }
  }

  int _parseChrRamSize(Uint8List rom) {
    if (_parseRomFormat(rom) == RomFormat.iNes) {
      return 0;
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
