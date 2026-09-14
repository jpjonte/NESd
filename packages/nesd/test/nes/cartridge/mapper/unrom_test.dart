import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/unrom.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../ui/mocks.dart';

const _prgBanks = 32;

Uint8List _buildRom() {
  const prgSize = _prgBanks * 0x4000;

  final rom = Uint8List(16 + prgSize)
    ..setAll(0, [0x4e, 0x45, 0x53, 0x1a, _prgBanks, 0, 0x20, 0]);

  for (var bank = 0; bank < _prgBanks; bank++) {
    rom[16 + bank * 0x4000] = bank;
  }

  return rom;
}

UNROM _buildUnrom() {
  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'unrom-test.nes',
      name: 'unrom-test.nes',
      type: FilesystemFileType.file,
    ),
    _buildRom(),
  )..databaseEntry = null;

  NES(cartridge: cartridge, eventBus: EventBus());

  return cartridge.mapper as UNROM;
}

void main() {
  group('UNROM', () {
    test('selects banks above 15 on oversized ROMs', () {
      final mapper = _buildUnrom()..cpuWrite(0x8000, 16);

      expect(mapper.cpuRead(0x8000), 16);
    });

    test('selects the last bank of a 32-bank ROM', () {
      final mapper = _buildUnrom()..cpuWrite(0x8000, 31);

      expect(mapper.cpuRead(0x8000), 31);
    });

    test('keeps the last bank fixed at \$C000', () {
      final mapper = _buildUnrom()..cpuWrite(0x8000, 5);

      expect(mapper.cpuRead(0xc000), _prgBanks - 1);
    });
  });
}
