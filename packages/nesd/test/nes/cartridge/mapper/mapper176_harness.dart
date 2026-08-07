import 'dart:typed_data';

import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/mapper176.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../ui/mocks.dart';

/// 2 MiB PRG = 256 banks of 8 KiB; 256 KiB CHR = 256 pages of 1 KiB.
const mapper176PrgBanks = 256;
const mapper176ChrPages = 256;

Uint8List _buildRom(int subMapper) {
  const prgSize = mapper176PrgBanks * 0x2000;
  const chrSize = mapper176ChrPages * 0x400;

  final rom = Uint8List(16 + prgSize + chrSize)
    ..setAll(0, [
      0x4e,
      0x45,
      0x53,
      0x1a,
      128,
      32,
      0x00,
      0xb8,
      subMapper << 4,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    ]);

  const prgStart = 16;
  const chrStart = prgStart + prgSize;

  for (var bank = 0; bank < mapper176PrgBanks; bank++) {
    rom[prgStart + bank * 0x2000] = bank & 0xff;
  }

  for (var page = 0; page < mapper176ChrPages; page++) {
    rom.fillRange(
      chrStart + page * 0x400,
      chrStart + (page + 1) * 0x400,
      page & 0xff,
    );
  }

  return rom;
}

final _roms = <int, Uint8List>{};

Mapper176 buildMapper176({int subMapper = 0}) {
  final rom = _roms.putIfAbsent(subMapper, () => _buildRom(subMapper));

  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'mapper176-test.nes',
      name: 'mapper176-test.nes',
      type: FilesystemFileType.file,
    ),
    rom,
  )..databaseEntry = null;

  NES(cartridge: cartridge, eventBus: EventBus());

  return cartridge.mapper as Mapper176;
}
