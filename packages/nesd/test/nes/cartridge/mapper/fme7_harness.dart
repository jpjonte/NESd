import 'dart:typed_data';

import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/fme7.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../ui/mocks.dart';

Uint8List buildFme7Rom({bool battery = false}) {
  const prgBanks = 8;
  const chrBanks = 8;

  final rom = Uint8List(16 + prgBanks * 0x4000 + chrBanks * 0x2000)
    ..setAll(0, [
      0x4e,
      0x45,
      0x53,
      0x1a,
      prgBanks,
      chrBanks,
      if (battery) 0x52 else 0x50,
      0x40,
    ]);

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

FME7 buildFme7({bool battery = false}) {
  final rom = buildFme7Rom(battery: battery);

  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'fme7-test.nes',
      name: 'fme7-test.nes',
      type: FilesystemFileType.file,
    ),
    rom,
  )..databaseEntry = null;

  NES(cartridge: cartridge, eventBus: EventBus());

  cartridge.reset();

  return cartridge.mapper as FME7;
}

void write(FME7 mapper, int command, int value) {
  mapper
    ..cpuWrite(0x8000, command)
    ..cpuWrite(0xa000, value);
}
