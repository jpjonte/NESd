import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/mapper34.dart';
import 'package:nesd/nes/cartridge/mapper/mapper34_state.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../ui/mocks.dart';

const _prgBankSize = 0x8000;
const _chrBankSize = 0x1000;

Uint8List _buildRom({
  required int mapperId,
  int subMapperId = 0,
  int prgBanks = 4,
  int chrBanks = 0,
  bool battery = false,
}) {
  final prgSize = prgBanks * _prgBankSize;
  final chrSize = chrBanks * _chrBankSize;

  final prgRamShift = battery ? 0x70 : 0x07;
  final chrRamShift = chrSize == 0 ? 0x07 : 0x00;

  final rom = Uint8List(16 + prgSize + chrSize)
    ..setAll(0, [
      0x4e, 0x45, 0x53, 0x1a, //
      prgBanks * 2, // 16 KiB PRG units
      chrSize ~/ 0x2000, // 8 KiB CHR units
      (mapperId & 0x0f) << 4 | (battery ? 0x02 : 0x00) | 0x01,
      mapperId & 0xf0 | 0x08, // NES 2.0
      subMapperId << 4 | mapperId >> 8,
      0x00,
      prgRamShift,
      chrRamShift,
    ]);

  for (var bank = 0; bank < prgBanks; bank++) {
    rom[16 + bank * _prgBankSize] = bank;
  }

  for (var bank = 0; bank < chrBanks; bank++) {
    rom[16 + prgSize + bank * _chrBankSize] = 0x10 + bank;
  }

  return rom;
}

Cartridge _buildCartridge({
  int mapperId = 34,
  int subMapperId = 0,
  int prgBanks = 4,
  int chrBanks = 0,
  bool battery = false,
}) {
  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'mapper-34-test.nes',
      name: 'mapper-34-test.nes',
      type: FilesystemFileType.file,
    ),
    _buildRom(
      mapperId: mapperId,
      subMapperId: subMapperId,
      prgBanks: prgBanks,
      chrBanks: chrBanks,
      battery: battery,
    ),
  )..databaseEntry = null;

  NES(cartridge: cartridge, eventBus: EventBus());

  cartridge.reset();

  return cartridge;
}

Cartridge _buildBnrom({int prgBanks = 4}) =>
    _buildCartridge(subMapperId: 2, prgBanks: prgBanks);

Cartridge _buildNina001() =>
    _buildCartridge(subMapperId: 1, prgBanks: 2, chrBanks: 16);

void main() {
  group('Mapper34', () {
    group('variant selection', () {
      test('picks BNROM for submapper 2', () {
        final mapper = _buildCartridge(subMapperId: 2, chrBanks: 4).mapper;

        expect(mapper, isA<Mapper34>());
        expect(mapper.name, 'BNROM');
      });

      test('picks NINA-001 for submapper 1', () {
        final mapper = _buildCartridge(subMapperId: 1, chrBanks: 2).mapper;

        expect(mapper.name, 'NINA-001');
      });

      test('picks BNROM for submapper 0 with CHR-RAM', () {
        expect(_buildCartridge().mapper.name, 'BNROM');
      });

      test('picks BNROM for submapper 0 with 8 KiB of CHR-ROM', () {
        expect(_buildCartridge(chrBanks: 2).mapper.name, 'BNROM');
      });

      test('picks NINA-001 for submapper 0 with more than 8 KiB CHR-ROM', () {
        expect(_buildCartridge(chrBanks: 4).mapper.name, 'NINA-001');
      });

      test('picks BNROM with WRAM for mapper 241', () {
        final mapper = _buildCartridge(mapperId: 241, chrBanks: 4).mapper;

        expect(mapper, isA<Mapper34>());
        expect(mapper.id, 241);
        expect(mapper.name, 'BxROM (WRAM)');
      });
    });

    group('BNROM', () {
      test('maps PRG bank 0 after reset', () {
        final cartridge = _buildBnrom();

        expect(cartridge.cpuRead(0x8000), 0);
      });

      test(r'selects the 32 KiB PRG bank by writing $8000-$FFFF', () {
        for (final address in [0x8000, 0xc123, 0xffff]) {
          final cartridge = _buildBnrom()..cpuWrite(address, 0x03);

          expect(cartridge.cpuRead(0x8000), 3, reason: 'at \$$address');
          expect(
            cartridge.cpuRead(0xffff),
            cartridge.prgRom[4 * _prgBankSize - 1],
          );
        }
      });

      test('reaches oversize PRG-ROM beyond 128 KiB', () {
        final cartridge = _buildBnrom(prgBanks: 8)..cpuWrite(0x8000, 0x06);

        expect(cartridge.cpuRead(0x8000), 6);
      });

      test('ignores the NINA-001 registers', () {
        final cartridge = _buildBnrom()..cpuWrite(0x7ffd, 0x01);

        expect(cartridge.cpuRead(0x8000), 0);
      });

      test('keeps CHR-RAM writable', () {
        final cartridge = _buildBnrom()..ppuWrite(0x1234, 0x5a);

        expect(cartridge.ppuRead(0x1234), 0x5a);
      });

      test('keeps the header mirroring', () {
        expect(_buildBnrom().nametableLayout, NametableLayout.horizontal);
      });

      test('restores the PRG bank from its state', () {
        final source = _buildBnrom()..cpuWrite(0x8000, 0x02);
        final state = source.mapper.state as Mapper34State;

        expect(state.prgBank, 2);

        final target = _buildBnrom()..mapper.state = state;

        expect(target.cpuRead(0x8000), 2);
      });
    });

    group('mapper 241', () {
      test(r'selects the 32 KiB PRG bank by writing $8000-$FFFF', () {
        final cartridge = _buildCartridge(mapperId: 241)..cpuWrite(0x9000, 1);

        expect(cartridge.cpuRead(0x8000), 1);
      });

      test(r'maps WRAM at $6000-$7FFF', () {
        final cartridge = _buildCartridge(mapperId: 241)
          ..cpuWrite(0x6000, 0x12)
          ..cpuWrite(0x7fff, 0x34);

        expect(cartridge.cpuRead(0x6000), 0x12);
        expect(cartridge.cpuRead(0x7fff), 0x34);
        expect(cartridge.cpuRead(0x8000), 0);
      });

      test('battery-backs the WRAM', () {
        final cartridge = _buildCartridge(mapperId: 241, battery: true)
          ..cpuWrite(0x6000, 0x56);

        expect(cartridge.prgSaveRam[0], 0x56);
      });

      test('keeps mapper id 241 in its state', () {
        final cartridge = _buildCartridge(mapperId: 241)..cpuWrite(0x8000, 3);

        expect(cartridge.mapper.state.id, 241);
      });
    });

    group('NINA-001', () {
      test('maps PRG bank 0 and CHR banks 0 and 1 after reset', () {
        final cartridge = _buildNina001();

        expect(cartridge.cpuRead(0x8000), 0);
        expect(cartridge.ppuRead(0x0000), 0x10);
        expect(cartridge.ppuRead(0x1000), 0x11);
      });

      test(r'selects the 32 KiB PRG bank with $7FFD', () {
        final cartridge = _buildNina001()..cpuWrite(0x7ffd, 0x01);

        expect(cartridge.cpuRead(0x8000), 1);
        expect(
          cartridge.cpuRead(0xffff),
          cartridge.prgRom[2 * _prgBankSize - 1],
        );
      });

      test(r'selects the 4 KiB CHR bank at PPU $0000 with $7FFE', () {
        final cartridge = _buildNina001()..cpuWrite(0x7ffe, 0x0c);

        expect(cartridge.ppuRead(0x0000), 0x10 + 12);
        expect(cartridge.ppuRead(0x1000), 0x11);
      });

      test(r'selects the 4 KiB CHR bank at PPU $1000 with $7FFF', () {
        final cartridge = _buildNina001()..cpuWrite(0x7fff, 0x0f);

        expect(cartridge.ppuRead(0x0000), 0x10);
        expect(cartridge.ppuRead(0x1000), 0x10 + 15);
      });

      test('writes the registers through to PRG-RAM', () {
        final cartridge = _buildNina001()
          ..cpuWrite(0x7ffd, 0x01)
          ..cpuWrite(0x7ffe, 0x05)
          ..cpuWrite(0x7fff, 0x09);

        expect(cartridge.cpuRead(0x7ffd), 0x01);
        expect(cartridge.cpuRead(0x7ffe), 0x05);
        expect(cartridge.cpuRead(0x7fff), 0x09);
      });

      test(r'maps PRG-RAM at $6000-$7FFF', () {
        final cartridge = _buildNina001()..cpuWrite(0x6000, 0x42);

        expect(cartridge.cpuRead(0x6000), 0x42);
      });

      test(r'ignores writes to $7FFC and $8000-$FFFF', () {
        final cartridge = _buildNina001()
          ..cpuWrite(0x7ffc, 0x01)
          ..cpuWrite(0x8000, 0x01);

        expect(cartridge.cpuRead(0x8000), 0);
        expect(cartridge.ppuRead(0x0000), 0x10);
        expect(cartridge.ppuRead(0x1000), 0x11);
      });

      test('keeps the header mirroring', () {
        expect(_buildNina001().nametableLayout, NametableLayout.horizontal);
      });

      test('restores the banks from its state', () {
        final source = _buildNina001()
          ..cpuWrite(0x7ffd, 0x01)
          ..cpuWrite(0x7ffe, 0x07)
          ..cpuWrite(0x7fff, 0x0a);
        final state = source.mapper.state as Mapper34State;

        expect(state.prgBank, 1);
        expect(state.chrBank0, 7);
        expect(state.chrBank1, 10);

        final target = _buildNina001()..mapper.state = state;

        expect(target.cpuRead(0x8000), 1);
        expect(target.ppuRead(0x0000), 0x10 + 7);
        expect(target.ppuRead(0x1000), 0x10 + 10);
      });
    });
  });
}
