import 'dart:typed_data';

import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/mapper45.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../ui/mocks.dart';

const mapper45PrgBanks = 256;
const mapper45ChrPages = 512;

Uint8List _buildRom({required bool chrRam}) {
  const prgSize = mapper45PrgBanks * 0x2000;
  final chrSize = chrRam ? 0 : mapper45ChrPages * 0x400;

  final rom = Uint8List(16 + prgSize + chrSize)
    ..setAll(0, [
      0x4e,
      0x45,
      0x53,
      0x1a,
      128, // 128 x 16 KiB = 2 MiB PRG
      if (chrRam) 0 else 64, // 64 x 8 KiB = 512 KiB CHR
      0xd1, // mapper 45; horizontal mode keeps chrBankMode 0
      0x20, // mapper 45 high nibble, iNES 1.0
      0,
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

  for (var bank = 0; bank < mapper45PrgBanks; bank++) {
    rom[prgStart + bank * 0x2000] = bank & 0xff;
  }

  if (!chrRam) {
    for (var page = 0; page < mapper45ChrPages; page++) {
      rom[chrStart + page * 0x400] = page & 0xff;
      rom[chrStart + page * 0x400 + 1] = page >> 8;
    }
  }

  return rom;
}

final _roms = <bool, Uint8List>{};

Mapper45 buildMapper45({bool chrRam = false}) {
  final rom = _roms.putIfAbsent(chrRam, () => _buildRom(chrRam: chrRam));

  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'mapper45-test.nes',
      name: 'mapper45-test.nes',
      type: FilesystemFileType.file,
    ),
    rom,
  )..databaseEntry = null;

  NES(cartridge: cartridge, eventBus: EventBus());

  return (cartridge.mapper as Mapper45)..reset();
}
