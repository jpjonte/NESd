import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../ui/mocks.dart';

/// Battery-backed NROM image: 1x16KB PRG, 1x8KB CHR.
Uint8List _batteryRom() {
  return Uint8List(16 + 0x4000 + 0x2000)
    ..setAll(0, const [0x4e, 0x45, 0x53, 0x1a, 1, 1, 0x02, 0]);
}

/// Returns a database entry forcing [prgSaveRamSize] bytes of save RAM, as
/// nes20db does for serial-EEPROM boards (e.g. 256 bytes for LZ93D50+24C02).
class _FixedSaveRamDatabase implements NesDatabase {
  const _FixedSaveRamDatabase(this.prgSaveRamSize);

  final int prgSaveRamSize;

  @override
  NesDatabaseEntry? find(RomInfo info) => NesDatabaseEntry(
    name: 'test',
    romHash: info.romHash ?? '',
    chrHash: null,
    prgHash: info.prgHash ?? '',
    chrRamSize: 0,
    prgRamSize: 0,
    prgSaveRamSize: prgSaveRamSize,
    hasBattery: true,
    mapper: 0,
    submapper: 0,
    expansion: 1,
  );
}

Cartridge _buildCartridge(NesDatabase database) {
  final cartridge = CartridgeFactory(database: database).fromFile(
    const FilesystemFile(
      path: 'mapper-test.nes',
      name: 'mapper-test.nes',
      type: FilesystemFileType.file,
    ),
    _batteryRom(),
  )..databaseEntry = null;

  NES(cartridge: cartridge, eventBus: EventBus());

  cartridge.reset();

  return cartridge;
}

void main() {
  test('save RAM smaller than a mapping block reads as open bus', () {
    final cartridge = _buildCartridge(const _FixedSaveRamDatabase(256));

    // A 256-byte serial-EEPROM buffer cannot back a full mapping block;
    // the range must behave as open bus instead of crashing.
    expect(cartridge.cpuRead(0x6000), 0);
    expect(cartridge.cpuRead(0x7fff), 0);

    cartridge.cpuWrite(0x6000, 0xab);

    expect(cartridge.cpuRead(0x6000), 0);
  });

  test('8KB save RAM round-trips reads and writes', () {
    final cartridge = _buildCartridge(MockNesDatabase())
      ..cpuWrite(0x6000, 0xab)
      ..cpuWrite(0x7fff, 0xcd);

    expect(cartridge.cpuRead(0x6000), 0xab);
    expect(cartridge.cpuRead(0x7fff), 0xcd);
  });
}
