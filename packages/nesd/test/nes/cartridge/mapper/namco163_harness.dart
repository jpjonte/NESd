import 'dart:typed_data';

import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/namco163.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../ui/mocks.dart';

Uint8List buildNamco163Rom({bool batteryOnly = false}) {
  const prgBanks = 8;
  const chrBanks = 8;

  final rom = Uint8List(16 + prgBanks * 0x4000 + chrBanks * 0x2000)
    ..setAll(0, const [0x4e, 0x45, 0x53, 0x1a, prgBanks, chrBanks, 0x30, 0x10]);

  if (batteryOnly) {
    rom
      ..[6] = 0x32
      ..[7] = 0x18
      ..[10] = 0x70;
  }

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

Namco163 buildNamco163({bool batteryOnly = false}) {
  final rom = buildNamco163Rom(batteryOnly: batteryOnly);

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
