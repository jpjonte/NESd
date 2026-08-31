import 'package:flutter/foundation.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/unrom512.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../ui/mocks.dart';

const unrom512PrgBanks = 32;

const unrom512SectorSize = 0x1000;

@immutable
class Unrom512Config {
  const Unrom512Config({
    this.subMapper = 0,
    this.battery = false,
    this.fourScreen = false,
    this.horizontalArrangement = false,
    this.chrRamShift = 9,
    this.prgBanks = unrom512PrgBanks,
  });

  final int subMapper;
  final bool battery;
  final bool fourScreen;
  final bool horizontalArrangement;

  final int chrRamShift;

  final int prgBanks;

  @override
  bool operator ==(Object other) =>
      other is Unrom512Config &&
      other.subMapper == subMapper &&
      other.battery == battery &&
      other.fourScreen == fourScreen &&
      other.horizontalArrangement == horizontalArrangement &&
      other.chrRamShift == chrRamShift &&
      other.prgBanks == prgBanks;

  @override
  int get hashCode => Object.hash(
    subMapper,
    battery,
    fourScreen,
    horizontalArrangement,
    chrRamShift,
    prgBanks,
  );
}

Uint8List _buildRom(Unrom512Config config) {
  final prgSize = config.prgBanks * 0x4000;

  final flags6 =
      0xe0 |
      (config.fourScreen ? 0x08 : 0x00) |
      (config.battery ? 0x02 : 0x00) |
      (config.horizontalArrangement ? 0x01 : 0x00);

  final rom = Uint8List(16 + prgSize)
    ..setAll(0, [
      0x4e,
      0x45,
      0x53,
      0x1a,
      config.prgBanks, // PRG-ROM size in 16 KiB banks
      0, // no CHR-ROM
      flags6,
      0x18, // mapper high nibble 1 + NES 2.0 marker
      config.subMapper << 4,
      0,
      0, // no PRG-RAM, no PRG-NVRAM
      config.chrRamShift, // CHR-RAM size = 64 << shift
      0,
      0,
      0,
      0,
    ]);

  const prgStart = 16;

  for (var bank = 0; bank < config.prgBanks; bank++) {
    rom.fillRange(
      prgStart + bank * 0x4000,
      prgStart + (bank + 1) * 0x4000,
      bank,
    );
  }

  return rom;
}

final _roms = <Unrom512Config, Uint8List>{};

UNROM512 buildUnrom512({
  int subMapper = 0,
  bool battery = false,
  bool fourScreen = false,
  bool horizontalArrangement = false,
  int chrRamShift = 9,
  int prgBanks = unrom512PrgBanks,
}) {
  final config = Unrom512Config(
    subMapper: subMapper,
    battery: battery,
    fourScreen: fourScreen,
    horizontalArrangement: horizontalArrangement,
    chrRamShift: chrRamShift,
    prgBanks: prgBanks,
  );

  final rom = _roms.putIfAbsent(config, () => _buildRom(config));

  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'unrom512-test.nes',
      name: 'unrom512-test.nes',
      type: FilesystemFileType.file,
    ),
    rom,
  )..databaseEntry = null;

  NES(cartridge: cartridge, eventBus: EventBus());

  cartridge.reset();

  return cartridge.mapper as UNROM512;
}
