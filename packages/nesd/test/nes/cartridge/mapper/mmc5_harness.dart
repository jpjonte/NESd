import 'dart:typed_data';

import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/mmc5.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../ui/mocks.dart';

/// Minimal in-memory iNES image with mapper 5 (flags6 = 0x50), 128 KB
/// PRG, 64 KB CHR. Enough for MMC5's bank math and register decode, no
/// ROM file needed.
MMC5 buildMmc5() {
  const prgBanks = 8;
  const chrBanks = 8;

  final rom = Uint8List(16 + prgBanks * 0x4000 + chrBanks * 0x2000)
    ..setAll(0, const [0x4e, 0x45, 0x53, 0x1a, prgBanks, chrBanks, 0x50, 0]);

  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'mmc5-test.nes',
      name: 'mmc5-test.nes',
      type: FilesystemFileType.file,
    ),
    rom,
  )..databaseEntry = null;

  NES(cartridge: cartridge, eventBus: EventBus());

  return cartridge.mapper as MMC5;
}
