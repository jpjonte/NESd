import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/mapper87.dart';
import 'package:nesd/nes/cartridge/mapper/mapper87_state.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../ui/mocks.dart';

const _chrBanks = 4;
const _prgUnitSize = 0x4000;
const _chrBankSize = 0x2000;

Uint8List _buildRom({required int prgUnits}) {
  final prgSize = prgUnits * _prgUnitSize;
  const chrSize = _chrBanks * _chrBankSize;

  final rom = Uint8List(16 + prgSize + chrSize)
    ..setAll(0, [
      0x4e, 0x45, 0x53, 0x1a, //
      prgUnits, // 16 KiB PRG units
      _chrBanks, // 8 KiB CHR units
      0x70 | 0x01, // mapper 87 low nibble, vertical mirroring
      0x50, // mapper 87 high nibble
    ]);

  for (var unit = 0; unit < prgUnits; unit++) {
    rom[16 + unit * _prgUnitSize] = unit;
  }

  for (var bank = 0; bank < _chrBanks; bank++) {
    rom[16 + prgSize + bank * _chrBankSize] = 0x10 + bank;
  }

  return rom;
}

Cartridge _buildCartridge({int prgUnits = 2}) {
  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'j87-test.nes',
      name: 'j87-test.nes',
      type: FilesystemFileType.file,
    ),
    _buildRom(prgUnits: prgUnits),
  )..databaseEntry = null;

  NES(cartridge: cartridge, eventBus: EventBus());

  cartridge.reset();

  return cartridge;
}

void main() {
  group('Mapper87', () {
    test('is selected for mapper 87', () {
      final mapper = _buildCartridge().mapper;

      expect(mapper, isA<Mapper87>());
      expect(mapper.id, 87);
      expect(mapper.name, 'J87');
    });

    test('maps 32 KiB PRG and CHR bank 0 after reset', () {
      final cartridge = _buildCartridge();

      expect(cartridge.cpuRead(0x8000), 0);
      expect(cartridge.cpuRead(0xc000), 1);
      expect(cartridge.ppuRead(0x0000), 0x10);
    });

    test('mirrors 16 KiB PRG into both halves', () {
      final cartridge = _buildCartridge(prgUnits: 1);

      expect(cartridge.cpuRead(0x8000), 0);
      expect(cartridge.cpuRead(0xc000), 0);
    });

    test('selects the CHR bank with bits 0 and 1 swapped', () {
      for (final (value, bank) in [
        (0x00, 0),
        (0x01, 2),
        (0x02, 1),
        (0x03, 3),
      ]) {
        final cartridge = _buildCartridge()..cpuWrite(0x6000, value);

        expect(cartridge.ppuRead(0x0000), 0x10 + bank, reason: 'value $value');
      }
    });

    test('ignores bits 2-7', () {
      final cartridge = _buildCartridge()..cpuWrite(0x6000, 0xfd);

      expect(cartridge.ppuRead(0x0000), 0x10 + 2);
    });

    test('decodes the register across \$6000-\$7fff', () {
      for (final address in [0x6000, 0x6001, 0x6abc, 0x7fff]) {
        final cartridge = _buildCartridge()..cpuWrite(address, 0x02);

        expect(cartridge.ppuRead(0x0000), 0x10 + 1, reason: '\$$address');
      }
    });

    test('ignores writes outside the register window', () {
      for (final address in [0x4020, 0x5fff, 0x8000, 0xe000, 0xffff]) {
        final cartridge = _buildCartridge()..cpuWrite(address, 0x02);

        expect(cartridge.ppuRead(0x0000), 0x10, reason: '\$$address');
      }
    });

    test('does not switch PRG', () {
      final cartridge = _buildCartridge()..cpuWrite(0x6000, 0xff);

      expect(cartridge.cpuRead(0x8000), 0);
      expect(cartridge.cpuRead(0xc000), 1);
    });

    test('keeps the header mirroring', () {
      final cartridge = _buildCartridge();

      expect(cartridge.nametableLayout, NametableLayout.horizontal);
    });

    test('resets the CHR bank', () {
      final cartridge = _buildCartridge()
        ..cpuWrite(0x6000, 0x03)
        ..reset();

      expect(cartridge.ppuRead(0x0000), 0x10);
    });

    test('restores the CHR bank from its state', () {
      final source = _buildCartridge()..cpuWrite(0x6000, 0x01);
      final state = source.mapper.state as Mapper87State;

      expect(state.chrBank, 2);

      final target = _buildCartridge()..mapper.state = state;

      expect(target.ppuRead(0x0000), 0x10 + 2);
    });
  });
}
