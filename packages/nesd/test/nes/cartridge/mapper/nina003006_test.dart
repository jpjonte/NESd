import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/nina003006.dart';
import 'package:nesd/nes/cartridge/mapper/nina003006_state.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../ui/mocks.dart';

const _prgBanks = 2;
const _chrBanks = 8;
const _prgBankSize = 0x8000;
const _chrBankSize = 0x2000;

Uint8List _buildRom() {
  const prgSize = _prgBanks * _prgBankSize;
  const chrSize = _chrBanks * _chrBankSize;

  final rom = Uint8List(16 + prgSize + chrSize)
    ..setAll(0, [
      0x4e, 0x45, 0x53, 0x1a, //
      _prgBanks * 2, // 16 KiB PRG units
      _chrBanks, // 8 KiB CHR units
      0xf1, // mapper 79 low nibble, vertical mirroring
      0x40, // mapper 79 high nibble
    ]);

  for (var bank = 0; bank < _prgBanks; bank++) {
    rom[16 + bank * _prgBankSize] = bank;
  }

  for (var bank = 0; bank < _chrBanks; bank++) {
    rom[16 + prgSize + bank * _chrBankSize] = 0x10 + bank;
  }

  return rom;
}

Cartridge _buildCartridge() {
  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'nina-003-006-test.nes',
      name: 'nina-003-006-test.nes',
      type: FilesystemFileType.file,
    ),
    _buildRom(),
  )..databaseEntry = null;

  NES(cartridge: cartridge, eventBus: EventBus());

  cartridge.reset();

  return cartridge;
}

void main() {
  group('NINA003006', () {
    test('is selected for mapper 79', () {
      expect(_buildCartridge().mapper, isA<NINA003006>());
    });

    test('maps PRG bank 0 and CHR bank 0 after reset', () {
      final cartridge = _buildCartridge();

      expect(cartridge.cpuRead(0x8000), 0);
      expect(cartridge.ppuRead(0x0000), 0x10);
    });

    test('selects the 32 KiB PRG bank from bit 3', () {
      final cartridge = _buildCartridge()..cpuWrite(0x4100, 0x08);

      expect(cartridge.cpuRead(0x8000), 1);
      expect(cartridge.cpuRead(0xffff), cartridge.prgRom[2 * _prgBankSize - 1]);
    });

    test('selects the 8 KiB CHR bank from bits 0-2', () {
      final cartridge = _buildCartridge()..cpuWrite(0x4100, 0x05);

      expect(cartridge.cpuRead(0x8000), 0);
      expect(cartridge.ppuRead(0x0000), 0x10 + 5);
    });

    test('ignores bits 4-7', () {
      final cartridge = _buildCartridge()..cpuWrite(0x4100, 0xf2);

      expect(cartridge.cpuRead(0x8000), 0);
      expect(cartridge.ppuRead(0x0000), 0x10 + 2);
    });

    test('decodes the register at every address matching 010x xxx1', () {
      for (final address in [0x4100, 0x41ff, 0x4300, 0x5d80, 0x5fff]) {
        final cartridge = _buildCartridge()..cpuWrite(address, 0x0b);

        expect(cartridge.cpuRead(0x8000), 1, reason: 'PRG at \$$address');
        expect(cartridge.ppuRead(0x0000), 0x10 + 3, reason: 'CHR');
      }
    });

    test('ignores writes outside the register window', () {
      for (final address in [0x4020, 0x4200, 0x5e00, 0x6100, 0x8000, 0xc100]) {
        final cartridge = _buildCartridge()..cpuWrite(address, 0x0b);

        expect(cartridge.cpuRead(0x8000), 0, reason: 'PRG at \$$address');
        expect(cartridge.ppuRead(0x0000), 0x10, reason: 'CHR');
      }
    });

    test('keeps the header mirroring', () {
      final cartridge = _buildCartridge();

      expect(cartridge.nametableLayout, NametableLayout.horizontal);
    });

    test('restores the banks from its state', () {
      final source = _buildCartridge()..cpuWrite(0x4100, 0x0e);
      final state = source.mapper.state as NINA003006State;

      expect(state.prgBank, 1);
      expect(state.chrBank, 6);

      final target = _buildCartridge()..mapper.state = state;

      expect(target.cpuRead(0x8000), 1);
      expect(target.ppuRead(0x0000), 0x10 + 6);
    });
  });
}
