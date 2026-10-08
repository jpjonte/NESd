import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

class _FakeNesDatabase extends Mock implements NesDatabase {
  _FakeNesDatabase(this.entry);

  final NesDatabaseEntry? entry;

  @override
  NesDatabaseEntry? find(RomInfo info) => entry;
}

const _file = FilesystemFile(
  path: '/roms/game.nes',
  name: 'game.nes',
  type: FilesystemFileType.file,
);

Uint8List _buildRom({required int mapper, required bool verticalMirroring}) {
  final flags6 = ((mapper & 0x0f) << 4) | (verticalMirroring ? 0x01 : 0x00);

  return Uint8List(16 + 2 * 0x4000 + 0x2000)
    ..setAll(0, [0x4e, 0x45, 0x53, 0x1a, 2, 1, flags6, mapper & 0xf0]);
}

NesDatabaseEntry _entry({
  required int mapper,
  required NametableLayout? nametableLayout,
}) {
  return NesDatabaseEntry(
    name: 'game',
    romHash: '',
    chrHash: null,
    prgHash: '',
    chrRamSize: 0,
    prgRamSize: 0,
    prgSaveRamSize: 0,
    hasBattery: false,
    mapper: mapper,
    submapper: 0,
    expansion: 1,
    nametableLayout: nametableLayout,
  );
}

Cartridge _load(Uint8List rom, NesDatabaseEntry? entry) {
  return CartridgeFactory(
    database: _FakeNesDatabase(entry),
  ).fromFile(_file, rom);
}

void main() {
  group('nametable layout', () {
    test('comes from the header without a database entry', () {
      final cartridge = _load(
        _buildRom(mapper: 0, verticalMirroring: true),
        null,
      );

      expect(cartridge.nametableLayout, NametableLayout.horizontal);
    });

    test('comes from the database on a fixed-mirroring board', () {
      final cartridge = _load(
        _buildRom(mapper: 0, verticalMirroring: false),
        _entry(mapper: 0, nametableLayout: NametableLayout.horizontal),
      );

      expect(cartridge.nametableLayout, NametableLayout.horizontal);
    });

    test('ignores the database on a mapper-controlled board', () {
      final cartridge = _load(
        _buildRom(mapper: 1, verticalMirroring: false),
        _entry(mapper: 1, nametableLayout: NametableLayout.horizontal),
      );

      expect(cartridge.nametableLayout, NametableLayout.vertical);
    });

    test('comes from the database on Bandai 74*161/32 (mapper 70)', () {
      final cartridge = _load(
        _buildRom(mapper: 70, verticalMirroring: false),
        _entry(mapper: 70, nametableLayout: NametableLayout.horizontal),
      );

      expect(cartridge.nametableLayout, NametableLayout.horizontal);
    });

    test('ignores the database on Bandai 74*161/161/32 (mapper 152)', () {
      final cartridge = _load(
        _buildRom(mapper: 152, verticalMirroring: false),
        _entry(mapper: 152, nametableLayout: NametableLayout.horizontal),
      );

      expect(cartridge.nametableLayout, NametableLayout.vertical);
    });

    test('keeps the header when the database has no H/V value', () {
      final cartridge = _load(
        _buildRom(mapper: 0, verticalMirroring: true),
        _entry(mapper: 0, nametableLayout: null),
      );

      expect(cartridge.nametableLayout, NametableLayout.horizontal);
    });
  });
}
