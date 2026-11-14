import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/mapper185.dart';
import 'package:nesd/nes/cartridge/mapper/mapper185_state.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../ui/mocks.dart';

const _prgSize = 0x8000;
const _chrSize = 0x2000;

const _chrMarker = 0x3c;
const _chrThirdByte = 0x5a;
const _disabled = 0xff;

const _conflictAddress = 0x9000;
const _conflictByte = 0xfc;

Uint8List _buildRom(int subMapperId) {
  final rom = Uint8List(16 + _prgSize + _chrSize)
    ..setAll(0, [
      0x4e, 0x45, 0x53, 0x1a, //
      _prgSize ~/ 0x4000,
      _chrSize ~/ 0x2000,
      0x90 | 0x01, // mapper 185 low nibble, vertical mirroring
      0xb0 | 0x08, // mapper 185 high nibble, NES 2.0
      subMapperId << 4,
    ])
    ..fillRange(16, 16 + _prgSize, 0xff);

  rom[16 + (_conflictAddress - 0x8000)] = _conflictByte;
  rom[16 + _prgSize] = _chrMarker;
  rom[16 + _prgSize + 2] = _chrThirdByte;

  return rom;
}

(Cartridge, NES) _build(int subMapperId) {
  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    FilesystemFile(
      path: 'mapper185-$subMapperId-test.nes',
      name: 'mapper185-$subMapperId-test.nes',
      type: FilesystemFileType.file,
    ),
    _buildRom(subMapperId),
  )..databaseEntry = null;

  final nes = NES(cartridge: cartridge, eventBus: EventBus());

  cartridge.reset();

  return (cartridge, nes);
}

void main() {
  test('mapper 185 is selected', () {
    final (cartridge, _) = _build(4);

    expect(cartridge.mapper, isA<Mapper185>());
    expect(cartridge.mapper.id, 185);
  });

  test('maps 32 KiB of PRG-ROM unbanked', () {
    final (cartridge, _) = _build(4);

    cartridge.cpuWrite(0x8000, 0x03);

    expect(cartridge.cpuRead(_conflictAddress), _conflictByte);
  });

  for (final (subMapperId, chipSelect) in [(4, 0), (5, 1), (6, 2), (7, 3)]) {
    group('submapper $subMapperId', () {
      test('enables CHR-ROM only for chip select $chipSelect', () {
        final (cartridge, _) = _build(subMapperId);

        for (var value = 0; value < 4; value++) {
          cartridge.cpuWrite(0x8000, 0x10 | value);

          expect(
            cartridge.ppuRead(0x0000),
            value == chipSelect ? _chrMarker : _disabled,
            reason: 'latch \$1$value',
          );
        }
      });

      test('ignores latch bits above the chip select', () {
        final (cartridge, _) = _build(subMapperId);

        cartridge.cpuWrite(0x8000, 0xfc | chipSelect);

        expect(cartridge.ppuRead(0x0000), _chrMarker);
      });
    });
  }

  test('ANDs the written value with the ROM byte (bus conflict)', () {
    final (cartridge, _) = _build(7);

    // $fc masks off both chip select bits: $03 latches as $00
    cartridge.cpuWrite(_conflictAddress, 0x03);

    expect(cartridge.ppuRead(0x0000), _disabled);

    cartridge.cpuWrite(0x8000, 0x03);

    expect(cartridge.ppuRead(0x0000), _chrMarker);
  });

  test('ignores writes below \$8000', () {
    final (cartridge, _) = _build(5);

    cartridge.cpuWrite(0x6000, 0x01);

    expect(cartridge.ppuRead(0x0000), _disabled);
  });

  test('keeps the header mirroring', () {
    final (cartridge, nes) = _build(4);

    cartridge
      ..cpuWrite(0x8000, 0xff)
      ..ppuWrite(0x2400, 0xaa);

    expect(nes.ppu.ram[0x400], 0xaa);
    expect(cartridge.ppuRead(0x2c00), 0xaa);
  });

  test('restores the latch from its state', () {
    final (source, _) = _build(6);

    source.cpuWrite(0x8000, 0x22);

    final state = source.mapper.state as Mapper185State;

    final (target, _) = _build(6);

    expect(target.ppuRead(0x0000), _disabled);

    target.mapper.state = state;

    expect(target.ppuRead(0x0000), _chrMarker);
  });

  group('submapper 0', () {
    test('disables CHR-ROM for the first two reads after reset', () {
      final (cartridge, _) = _build(0);

      expect(cartridge.ppuRead(0x0000), _disabled);
      expect(cartridge.ppuRead(0x0000), _disabled);
      expect(cartridge.ppuRead(0x0000), _chrMarker);
      expect(cartridge.ppuRead(0x0000), _chrMarker);
    });

    test('ignores the latch', () {
      final (cartridge, _) = _build(0);

      cartridge
        ..ppuRead(0x0000)
        ..ppuRead(0x0000)
        ..cpuWrite(0x8000, 0x00);

      expect(cartridge.ppuRead(0x0000), _chrMarker);
    });

    test('does not count side-effect-free reads', () {
      final (cartridge, _) = _build(0);

      for (var i = 0; i < 4; i++) {
        expect(cartridge.ppuRead(0x0000, disableSideEffects: true), _disabled);
      }

      expect(cartridge.ppuRead(0x0000), _disabled);
    });

    test('disables CHR-ROM again on reset', () {
      final (cartridge, _) = _build(0);

      cartridge
        ..ppuRead(0x0000)
        ..ppuRead(0x0000)
        ..reset();

      expect(cartridge.ppuRead(0x0000), _disabled);
    });

    test('restores the remaining disabled reads from its state', () {
      final (source, _) = _build(0);

      source.ppuRead(0x0000);

      final (target, _) = _build(0);

      target.mapper.state = source.mapper.state;

      expect(target.ppuRead(0x0000), _disabled);
      expect(target.ppuRead(0x0000), _chrMarker);
    });

    test('counts PPUDATA reads of the pattern tables', () {
      final (_, nes) = _build(0);

      int readPpuData() => nes.bus.cpuRead(0x2007);

      nes.bus
        ..cpuWrite(0x2006, 0x00)
        ..cpuWrite(0x2006, 0x00);

      readPpuData();

      expect(readPpuData(), _disabled);
      expect(readPpuData(), _disabled);
      expect(readPpuData(), _chrThirdByte);
    });
  });
}
