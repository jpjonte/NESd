import 'dart:typed_data';

import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/mmc3.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../ui/mocks.dart';

/// 512 KiB PRG = 64 banks of 8 KiB; 256 KiB CHR = 256 pages of 1 KiB.
const mmc3PrgBanks = 64;
const mmc3ChrPages = 256;

Uint8List _buildRom() {
  const prgSize = mmc3PrgBanks * 0x2000;
  const chrSize = mmc3ChrPages * 0x400;

  final rom = Uint8List(16 + prgSize + chrSize)
    ..setAll(0, const [0x4e, 0x45, 0x53, 0x1a, 32, 32, 0x40, 0x00]);

  const prgStart = 16;
  const chrStart = prgStart + prgSize;

  for (var bank = 0; bank < mmc3PrgBanks; bank++) {
    rom[prgStart + bank * 0x2000] = bank;
  }

  for (var page = 0; page < mmc3ChrPages; page++) {
    rom.fillRange(chrStart + page * 0x400, chrStart + (page + 1) * 0x400, page);
  }

  return rom;
}

final _rom = _buildRom();

MMC3 buildMmc3() {
  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'mmc3-test.nes',
      name: 'mmc3-test.nes',
      type: FilesystemFileType.file,
    ),
    _rom,
  )..databaseEntry = null;

  NES(cartridge: cartridge, eventBus: EventBus());

  return cartridge.mapper as MMC3;
}
