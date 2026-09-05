import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../ui/mocks.dart';

Uint8List _rom() {
  return Uint8List(16 + 0x4000 + 0x2000)
    ..setAll(0, const [0x4e, 0x45, 0x53, 0x1a, 1, 1, 0x00, 0]);
}

NES _buildNes() {
  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'decode-test.nes',
      name: 'decode-test.nes',
      type: FilesystemFileType.file,
    ),
    _rom(),
  )..databaseEntry = null;

  return NES(cartridge: cartridge, eventBus: EventBus())..reset();
}

void main() {
  group('stock mappers', () {
    test('mirrors PPU registers every eight bytes', () {
      final nes = _buildNes();

      nes.bus.cpuWrite(0x200b, 0x42);

      expect(nes.ppu.OAMADDR, 0x42);

      nes.bus.cpuWrite(0x3ffb, 0x24);

      expect(nes.ppu.OAMADDR, 0x24);
    });

    test('reads mirror down to the eight stock registers', () {
      final nes = _buildNes();

      nes.bus
        ..cpuWrite(0x2003, 0x05) // OAMADDR
        ..cpuWrite(0x2004, 0x99) // OAMDATA
        ..cpuWrite(0x2003, 0x05); // OAMADDR, back to the seeded slot

      expect(nes.bus.cpuRead(0x2004), 0x99);
      expect(nes.bus.cpuRead(0x200c), 0x99);
    });
  });
}
