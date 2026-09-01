import 'dart:typed_data';

import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/vt/mapper256.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../../ui/mocks.dart';

/// PRG-ROM size, multiples of 16 KB
const vtPrgBanks = 8;
const vtChrPages = 8;

Uint8List _buildRom(int prgBanks) {
  final prgSize = prgBanks * 0x4000;
  const chrSize = vtChrPages * 0x2000;

  final rom = Uint8List(16 + prgSize + chrSize)
    ..setAll(0, [
      0x4e, 0x45, 0x53, 0x1a, //
      prgBanks & 0xff, vtChrPages, 0x00, 0x08, 0x01, prgBanks >> 8, 0x00, 0x00,
    ]);

  const prgStart = 16;
  final chrStart = prgStart + prgSize;

  for (var bank = 0; bank < prgSize ~/ 0x2000; bank++) {
    final offset = prgStart + bank * 0x2000;

    rom[offset] = bank & 0xff;
    rom[offset + 1] = bank >> 8;
  }

  for (var page = 0; page < vtChrPages; page++) {
    rom.fillRange(
      chrStart + page * 0x2000,
      chrStart + (page + 1) * 0x2000,
      page,
    );
  }

  return rom;
}

final _roms = <int, Uint8List>{};

({NES nes, Mapper256 mapper}) buildVt02({int prgBanks = vtPrgBanks}) {
  final rom = _roms[prgBanks] ??= _buildRom(prgBanks);

  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'vt02-test.nes',
      name: 'vt02-test.nes',
      type: FilesystemFileType.file,
    ),
    rom,
  )..databaseEntry = null;

  final nes = NES(cartridge: cartridge, eventBus: EventBus());

  cartridge.reset();

  return (nes: nes, mapper: cartridge.mapper as Mapper256);
}
