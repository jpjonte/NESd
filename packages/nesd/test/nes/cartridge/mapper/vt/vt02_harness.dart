import 'dart:typed_data';

import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/vt/mapper256.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../../ui/mocks.dart';

const vtPrgBanks = 8;
const vtChrPages = 8;

Uint8List _buildRom() {
  const prgSize = vtPrgBanks * 0x4000;
  const chrSize = vtChrPages * 0x2000;

  final rom = Uint8List(16 + prgSize + chrSize)
    ..setAll(0, const [
      0x4e, 0x45, 0x53, 0x1a, //
      vtPrgBanks, vtChrPages, 0x00, 0x08, 0x01, 0x00, 0x00, 0x00,
    ]);

  const prgStart = 16;
  const chrStart = prgStart + prgSize;

  for (var bank = 0; bank < vtPrgBanks; bank++) {
    rom[prgStart + bank * 0x4000] = bank;
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

final _rom = _buildRom();

({NES nes, Mapper256 mapper}) buildVt02() {
  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'vt02-test.nes',
      name: 'vt02-test.nes',
      type: FilesystemFileType.file,
    ),
    _rom,
  )..databaseEntry = null;

  final nes = NES(cartridge: cartridge, eventBus: EventBus());

  cartridge.reset();

  return (nes: nes, mapper: cartridge.mapper as Mapper256);
}
