import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/bandai_discrete.dart';
import 'package:nesd/nes/cartridge/mapper/bandai_discrete_state.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../ui/mocks.dart';

const _prgBanks = 16;
const _chrBanks = 16;
const _prgBankSize = 0x4000;
const _chrBankSize = 0x2000;
const _prgSize = _prgBanks * _prgBankSize;

const _register = 0xc001;

Uint8List _buildRom(int mapperId) {
  const chrSize = _chrBanks * _chrBankSize;

  final rom = Uint8List(16 + _prgSize + chrSize)
    ..setAll(0, [
      0x4e, 0x45, 0x53, 0x1a, //
      _prgBanks,
      _chrBanks,
      (mapperId & 0x0f) << 4 | 0x01, // vertical mirroring
      mapperId & 0xf0,
    ])
    ..fillRange(16, 16 + _prgSize, 0xff);

  for (var bank = 0; bank < _prgBanks; bank++) {
    rom[16 + bank * _prgBankSize] = bank;
  }

  for (var bank = 0; bank < _chrBanks; bank++) {
    rom[16 + _prgSize + bank * _chrBankSize] = 0x10 + bank;
  }

  return rom;
}

(Cartridge, NES) _build(int mapperId) {
  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    FilesystemFile(
      path: 'bandai-discrete-$mapperId-test.nes',
      name: 'bandai-discrete-$mapperId-test.nes',
      type: FilesystemFileType.file,
    ),
    _buildRom(mapperId),
  )..databaseEntry = null;

  final nes = NES(cartridge: cartridge, eventBus: EventBus());

  cartridge.reset();

  return (cartridge, nes);
}

void main() {
  for (final mapperId in [70, 152]) {
    group('BandaiDiscrete mapper $mapperId', () {
      test('is selected', () {
        final (cartridge, _) = _build(mapperId);

        expect(cartridge.mapper, isA<BandaiDiscrete>());
        expect(cartridge.mapper.id, mapperId);
      });

      test('maps PRG bank 0, the last bank and CHR bank 0 after reset', () {
        final (cartridge, _) = _build(mapperId);

        expect(cartridge.cpuRead(0x8000), 0);
        expect(cartridge.cpuRead(0xc000), _prgBanks - 1);
        expect(cartridge.ppuRead(0x0000), 0x10);
      });

      test('selects the 16 KiB PRG bank at \$8000 from bits 4-6', () {
        final (cartridge, _) = _build(mapperId);

        cartridge.cpuWrite(_register, 0x50);

        expect(cartridge.cpuRead(0x8000), 5);
        expect(cartridge.cpuRead(0xc000), _prgBanks - 1);
      });

      test('selects the 8 KiB CHR bank from bits 0-3', () {
        final (cartridge, _) = _build(mapperId);

        cartridge.cpuWrite(_register, 0x0d);

        expect(cartridge.ppuRead(0x0000), 0x10 + 13);
      });

      test('ANDs the written value with the ROM byte (bus conflict)', () {
        final (cartridge, _) = _build(mapperId);

        // $c000 holds the last bank's marker, $0f
        cartridge.cpuWrite(0xc000, 0x37);

        expect(cartridge.cpuRead(0x8000), 0);
        expect(cartridge.ppuRead(0x0000), 0x10 + 7);
      });

      test('ignores writes below \$8000', () {
        final (cartridge, _) = _build(mapperId);

        cartridge
          ..cpuWrite(_register, 0x31)
          ..cpuWrite(0x7fff, 0x00);

        expect(cartridge.cpuRead(0x8000), 3);
        expect(cartridge.ppuRead(0x0000), 0x10 + 1);
      });

      test('restores the banks from its state', () {
        final (source, _) = _build(mapperId);

        source.cpuWrite(_register, 0x62);

        final state = source.mapper.state as BandaiDiscreteState;

        expect(state.id, mapperId);

        final (target, _) = _build(mapperId);

        target.mapper.state = state;

        expect(target.cpuRead(0x8000), 6);
        expect(target.ppuRead(0x0000), 0x10 + 2);
      });
    });
  }

  group('BandaiDiscrete mapper 70', () {
    test('uses bit 7 as PRG bank bit 3', () {
      final (cartridge, _) = _build(70);

      cartridge.cpuWrite(_register, 0x90);

      expect(cartridge.cpuRead(0x8000), 9);
    });

    test('keeps the header mirroring', () {
      final (cartridge, nes) = _build(70);

      cartridge
        ..cpuWrite(_register, 0x80)
        ..ppuWrite(0x2400, 0xaa);

      expect(nes.ppu.ram[0x400], 0xaa);
      expect(cartridge.ppuRead(0x2c00), 0xaa);
    });
  });

  group('BandaiDiscrete mapper 152', () {
    test('ignores bit 7 for PRG banking', () {
      final (cartridge, _) = _build(152);

      cartridge.cpuWrite(_register, 0x90);

      expect(cartridge.cpuRead(0x8000), 1);
    });

    test('selects one-screen mirroring from bit 7', () {
      final (cartridge, nes) = _build(152);

      cartridge.ppuWrite(0x2c00, 0x11);

      expect(nes.ppu.ram[0x000], 0x11);

      cartridge
        ..cpuWrite(_register, 0x80)
        ..ppuWrite(0x2000, 0x22);

      expect(nes.ppu.ram[0x400], 0x22);
      expect(cartridge.ppuRead(0x2800), 0x22);
    });

    test('restores the mirroring from its state', () {
      final (source, _) = _build(152);

      source.cpuWrite(_register, 0x80);

      final (target, nes) = _build(152);

      target
        ..mapper.state = source.mapper.state
        ..ppuWrite(0x2000, 0x33);

      expect(nes.ppu.ram[0x400], 0x33);
    });
  });
}
