import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/mmc5.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

/// Reports what nes20db.xml actually says for the battery-backed MMC5 boards:
/// no plain work RAM, 8 KB of battery-backed RAM.
class _BatteryBoardDatabase extends Mock implements NesDatabase {
  @override
  NesDatabaseEntry? find(RomInfo info) => NesDatabaseEntry(
    name: 'battery mmc5 board',
    romHash: info.romHash ?? '',
    chrHash: info.chrHash,
    prgHash: info.prgHash ?? '',
    chrRamSize: 0,
    prgRamSize: 0,
    prgSaveRamSize: 0x2000,
    hasBattery: true,
    mapper: 5,
    submapper: 0,
    expansion: 0,
  );
}

MMC5 buildBatteryMmc5() {
  const prgBanks = 8;
  const chrBanks = 8;

  final rom = Uint8List(16 + prgBanks * 0x4000 + chrBanks * 0x2000)
    ..setAll(0, const [0x4e, 0x45, 0x53, 0x1a, prgBanks, chrBanks, 0x52, 0]);

  final cartridge =
      CartridgeFactory(database: _BatteryBoardDatabase()).fromFile(
        const FilesystemFile(
          path: 'mmc5-battery.nes',
          name: 'mmc5-battery.nes',
          type: FilesystemFileType.file,
        ),
        rom,
      )..databaseEntry = null;

  NES(cartridge: cartridge, eventBus: EventBus());

  return cartridge.mapper as MMC5;
}

void main() {
  test('work RAM is mapped on a battery board with no plain PRG RAM', () {
    final mapper = buildBatteryMmc5();

    expect(mapper.cartridge.prgRam, isEmpty);
    expect(mapper.cartridge.prgSaveRam, isNotEmpty);

    // $5102/$5103 must both be unlocked before writes are accepted.
    mapper
      ..cpuWrite(0x5102, 0x02)
      ..cpuWrite(0x5103, 0x01)
      ..cpuWrite(0x6000, 0x5a)
      ..cpuWrite(0x7fff, 0xa5);

    expect(mapper.cpuRead(0x6000), 0x5a);
    expect(mapper.cpuRead(0x7fff), 0xa5);
  });
}
