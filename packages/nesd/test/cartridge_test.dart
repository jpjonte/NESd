import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import 'ui/mocks.dart';

Uint8List _buildRom({required bool hasBattery}) {
  const prgSize = 0x4000; // one 16KB PRG bank
  const chrSize = 0x2000; // one 8KB CHR bank

  // "NES\x1a" magic, 1 PRG bank, 1 CHR bank, flags6 (bit 1 = battery).
  return Uint8List(16 + prgSize + chrSize)
    ..setAll(0, [0x4e, 0x45, 0x53, 0x1a, 1, 1, if (hasBattery) 0x02 else 0x00]);
}

Cartridge _buildCartridge({required bool hasBattery}) {
  final factory = CartridgeFactory(database: MockNesDatabase());

  return factory.fromFile(
    const FilesystemFile(
      path: '/test.nes',
      name: 'test.nes',
      type: FilesystemFileType.file,
    ),
    _buildRom(hasBattery: hasBattery),
  )..databaseEntry = null;
}

void main() {
  test('load restores battery save RAM from the save bytes', () {
    final cartridge = _buildCartridge(hasBattery: true);
    final save = Uint8List.fromList(
      List.generate(cartridge.prgSaveRam.length, (i) => i & 0xff),
    );

    cartridge.load(save);

    expect(cartridge.prgSaveRam, equals(save));
    expect(cartridge.save(), equals(save));
  });

  test('load ignores save bytes without a battery', () {
    final cartridge = _buildCartridge(hasBattery: false);
    final save = Uint8List.fromList(
      List.filled(cartridge.prgSaveRam.length, 0xab),
    );

    cartridge.load(save);

    expect(cartridge.prgSaveRam, everyElement(0));
  });

  test('load tolerates a shorter save than the save RAM', () {
    final cartridge = _buildCartridge(hasBattery: true);
    final save = Uint8List.fromList(List.filled(16, 0xcd));

    cartridge.load(save);

    expect(cartridge.prgSaveRam.sublist(0, 16), everyElement(0xcd));
    expect(cartridge.prgSaveRam.sublist(16), everyElement(0));
  });

  test('load tolerates a longer save than the save RAM', () {
    final cartridge = _buildCartridge(hasBattery: true);
    final save = Uint8List.fromList(
      List.filled(cartridge.prgSaveRam.length + 16, 0xef),
    );

    cartridge.load(save);

    expect(cartridge.prgSaveRam, everyElement(0xef));
  });
}
