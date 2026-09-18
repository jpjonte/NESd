import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/color_dreams.dart';
import 'package:nesd/nes/cartridge/mapper/color_dreams_state.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../ui/mocks.dart';

const _prgBanks = 4;
const _chrBanks = 16;
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
      0xb0, // mapper 11 low nibble, vertical mirroring
      0,
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
      path: 'color-dreams-test.nes',
      name: 'color-dreams-test.nes',
      type: FilesystemFileType.file,
    ),
    _buildRom(),
  )..databaseEntry = null;

  NES(cartridge: cartridge, eventBus: EventBus());

  cartridge.reset();

  return cartridge;
}

void main() {
  group('ColorDreams', () {
    test('is selected for mapper 11', () {
      expect(_buildCartridge().mapper, isA<ColorDreams>());
    });

    test('maps PRG bank 0 and CHR bank 0 after reset', () {
      final cartridge = _buildCartridge();

      expect(cartridge.cpuRead(0x8000), 0);
      expect(cartridge.ppuRead(0x0000), 0x10);
    });

    test('selects the 32 KiB PRG bank from bits 0-1', () {
      final cartridge = _buildCartridge()..cpuWrite(0x8000, 0x02);

      expect(cartridge.cpuRead(0x8000), 2);
      expect(cartridge.cpuRead(0xffff), cartridge.prgRom[3 * _prgBankSize - 1]);
    });

    test('selects the 8 KiB CHR bank from bits 4-7', () {
      final cartridge = _buildCartridge()..cpuWrite(0xc000, 0xd0);

      expect(cartridge.ppuRead(0x0000), 0x10 + 13);
      expect(cartridge.ppuRead(0x1fff), 0);
    });

    test('ignores the lockout defeat bits', () {
      final cartridge = _buildCartridge()..cpuWrite(0xffff, 0x0c);

      expect(cartridge.cpuRead(0x8000), 0);
      expect(cartridge.ppuRead(0x0000), 0x10);
    });

    test('switches both banks from one write', () {
      final cartridge = _buildCartridge()..cpuWrite(0xa000, 0x51);

      expect(cartridge.cpuRead(0x8000), 1);
      expect(cartridge.ppuRead(0x0000), 0x10 + 5);
    });

    test('ignores writes below \$8000', () {
      final cartridge = _buildCartridge()
        ..cpuWrite(0x8000, 0x31)
        ..cpuWrite(0x7fff, 0x00);

      expect(cartridge.cpuRead(0x8000), 1);
      expect(cartridge.ppuRead(0x0000), 0x10 + 3);
    });

    test('restores the banks from its state', () {
      final source = _buildCartridge()..cpuWrite(0x8000, 0x72);
      final state = source.mapper.state as ColorDreamsState;

      expect(state.prgBank, 2);
      expect(state.chrBank, 7);

      final target = _buildCartridge()..mapper.state = state;

      expect(target.cpuRead(0x8000), 2);
      expect(target.ppuRead(0x0000), 0x10 + 7);
    });
  });
}
