import 'dart:typed_data';

import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/namco163.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../ui/mocks.dart';

/// Minimal in-memory iNES image with mapper 19, 128 KB PRG and 64 KB CHR.
///
/// PRG and CHR banks are filled with unique values so they can be
/// distinguished.
Uint8List buildNamco163Rom() {
  const prgBanks = 8;
  const chrBanks = 8;

  final rom = Uint8List(16 + prgBanks * 0x4000 + chrBanks * 0x2000)
    ..setAll(0, const [0x4e, 0x45, 0x53, 0x1a, prgBanks, chrBanks, 0x30, 0x10]);

  const prgStart = 16;
  const chrStart = prgStart + prgBanks * 0x4000;

  for (var bank = 0; bank < prgBanks * 2; bank++) {
    rom[prgStart + bank * 0x2000] = 0xb0 + bank;
  }

  for (var page = 0; page < chrBanks * 8; page++) {
    rom.fillRange(
      chrStart + page * 0x400,
      chrStart + (page + 1) * 0x400,
      0x10 + page,
    );
  }

  return rom;
}

Namco163 buildNamco163() {
  final rom = buildNamco163Rom();

  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'namco163-test.nes',
      name: 'namco163-test.nes',
      type: FilesystemFileType.file,
    ),
    rom,
  )..databaseEntry = null;

  NES(cartridge: cartridge, eventBus: EventBus());

  return cartridge.mapper as Namco163;
}
