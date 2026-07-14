import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import 'ui/mocks.dart';

Uint8List _buildRom({required int chrBanks}) {
  const prgSize = 0x4000; // one 16KB PRG bank
  final chrSize = chrBanks * 0x2000;

  // "NES\x1a" magic, iNES 1.0, 1 PRG bank, `chrBanks` CHR banks, mapper 0.
  return Uint8List(16 + prgSize + chrSize)
    ..setAll(0, [0x4e, 0x45, 0x53, 0x1a, 1, chrBanks]);
}

void main() {
  test('iNES 1.0 with 0 CHR banks gets a writable 8KB CHR RAM', () {
    final factory = CartridgeFactory(database: MockNesDatabase());

    final cartridge = factory.fromFile(
      const FilesystemFile(
        path: '/chr-ram.nes',
        name: 'chr-ram.nes',
        type: FilesystemFileType.file,
      ),
      _buildRom(chrBanks: 0),
    )..databaseEntry = null;

    expect(cartridge.chrRam.length, equals(0x2000));

    final nes = NES(cartridge: cartridge, eventBus: EventBus());

    nes.bus.cartridge.reset();
    nes.bus.cartridge.ppuWrite(0x0000, 0x42);

    expect(cartridge.chrRam[0], equals(0x42));
  });

  test('iNES 1.0 with CHR banks keeps CHR RAM empty', () {
    final factory = CartridgeFactory(database: MockNesDatabase());

    final cartridge = factory.fromFile(
      const FilesystemFile(
        path: '/chr-rom.nes',
        name: 'chr-rom.nes',
        type: FilesystemFileType.file,
      ),
      _buildRom(chrBanks: 1),
    )..databaseEntry = null;

    expect(cartridge.chrRam, isEmpty);
  });
}
