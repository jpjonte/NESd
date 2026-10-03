import 'dart:typed_data';

import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/mmc3_chr_ram.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../ui/mocks.dart';

const mmc3ChrRamPrgBanks = 32;
const mmc3ChrRamChrPages = 64;

Uint8List _buildRom(int mapperId) {
  const prgSize = mmc3ChrRamPrgBanks * 0x2000;
  const chrSize = mmc3ChrRamChrPages * 0x400;

  final rom = Uint8List(16 + prgSize + chrSize)
    ..setAll(0, [
      0x4e,
      0x45,
      0x53,
      0x1a,
      prgSize ~/ 0x4000,
      chrSize ~/ 0x2000,
      (mapperId & 0x0f) << 4,
      mapperId & 0xf0,
    ]);

  const prgStart = 16;
  const chrStart = prgStart + prgSize;

  for (var bank = 0; bank < mmc3ChrRamPrgBanks; bank++) {
    rom[prgStart + bank * 0x2000] = bank;
  }

  for (var page = 0; page < mmc3ChrRamChrPages; page++) {
    rom.fillRange(chrStart + page * 0x400, chrStart + (page + 1) * 0x400, page);
  }

  return rom;
}

final _roms = <int, Uint8List>{};

MMC3ChrRam buildMmc3ChrRam(int mapperId) {
  final rom = _roms.putIfAbsent(mapperId, () => _buildRom(mapperId));

  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'mmc3-chr-ram-test.nes',
      name: 'mmc3-chr-ram-test.nes',
      type: FilesystemFileType.file,
    ),
    rom,
  )..databaseEntry = null;

  NES(cartridge: cartridge, eventBus: EventBus());

  cartridge.reset();

  return cartridge.mapper as MMC3ChrRam;
}
