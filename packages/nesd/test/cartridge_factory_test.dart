import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
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

Uint8List _buildNes20Rom({
  required int prgLsb,
  required int prgMsb,
  required int chrLsb,
  required int chrMsb,
  required int prgBytes,
  required int chrBytes,
  int byte10 = 0,
  int byte11 = 0,
  bool battery = false,
}) {
  final flags6 = battery ? 0x02 : 0x00;

  final rom = Uint8List(16 + prgBytes + chrBytes)
    ..setAll(0, [
      0x4e, 0x45, 0x53, 0x1a,
      prgLsb, chrLsb,
      flags6, 0x08, // mapper 0, NES 2.0 marker in byte 7
      0x00,
      (chrMsb << 4) | prgMsb,
      byte10,
      byte11,
    ]);

  if (chrBytes > 0) {
    rom[16 + prgBytes] = 0xc5; // stamp the first CHR byte
  }

  return rom;
}

Cartridge _load(Uint8List rom) =>
    CartridgeFactory(database: MockNesDatabase()).fromFile(
      const FilesystemFile(
        path: '/nes20.nes',
        name: 'nes20.nes',
        type: FilesystemFileType.file,
      ),
      rom,
    )..databaseEntry = null;

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

  group('NES 2.0 size fields', () {
    test('CHR size MSB nibble is honoured', () {
      final cartridge = _load(
        _buildNes20Rom(
          prgLsb: 1,
          prgMsb: 0,
          chrLsb: 0,
          chrMsb: 1,
          prgBytes: 0x4000,
          chrBytes: 256 * 0x2000,
        ),
      );

      expect(cartridge.chrRom.length, 256 * 0x2000);
      expect(cartridge.chrRom[0], 0xc5);

      NES(cartridge: cartridge, eventBus: EventBus());

      cartridge.reset();

      expect(cartridge.ppuRead(0x0000), 0xc5);
    });

    test('PRG size MSB nibble is honoured, and CHR starts after it', () {
      final cartridge = _load(
        _buildNes20Rom(
          prgLsb: 0,
          prgMsb: 1,
          chrLsb: 1,
          chrMsb: 0,
          prgBytes: 256 * 0x4000,
          chrBytes: 0x2000,
        ),
      );

      expect(cartridge.prgRom.length, 256 * 0x4000);
      expect(cartridge.chrRom[0], 0xc5);
    });

    test('exponent-multiplier form is decoded', () {
      final cartridge = _load(
        _buildNes20Rom(
          prgLsb: 14 << 2,
          prgMsb: 0x0f,
          chrLsb: 1,
          chrMsb: 0,
          prgBytes: 0x4000,
          chrBytes: 0x2000,
        ),
      );

      expect(cartridge.prgRom.length, 0x4000);
      expect(cartridge.chrRom[0], 0xc5);
    });

    test('iNES 1.0 ignores byte 9 entirely', () {
      final rom = _buildRom(chrBanks: 1)..[9] = 0x11;

      final cartridge = _load(rom);

      expect(cartridge.prgRom.length, 0x4000);
      expect(cartridge.chrRom.length, 0x2000);
    });
  });

  group('NES 2.0 RAM size fields', () {
    test('a zero CHR-RAM shift count means no CHR-RAM', () {
      final cartridge = _load(
        _buildNes20Rom(
          prgLsb: 1,
          prgMsb: 0,
          chrLsb: 1,
          chrMsb: 0,
          prgBytes: 0x4000,
          chrBytes: 0x2000,
        ),
      );

      expect(cartridge.chrRam, isEmpty);
      expect(cartridge.chrRom.length, 0x2000);
      expect(cartridge.chrRom[0], 0xc5);
    });

    test('a non-zero CHR-RAM shift count is 64 << shift', () {
      final cartridge = _load(
        _buildNes20Rom(
          prgLsb: 1,
          prgMsb: 0,
          chrLsb: 0,
          chrMsb: 0,
          prgBytes: 0x4000,
          chrBytes: 0,
          byte11: 7,
        ),
      );

      expect(cartridge.chrRam.length, 64 << 7);
    });

    test('PRG-RAM comes from byte 10 low nibble', () {
      final cartridge = _load(
        _buildNes20Rom(
          prgLsb: 1,
          prgMsb: 0,
          chrLsb: 1,
          chrMsb: 0,
          prgBytes: 0x4000,
          chrBytes: 0x2000,
          byte10: 7,
        ),
      );

      expect(cartridge.prgRam.length, 64 << 7);
      expect(cartridge.prgSaveRam, isEmpty);
    });

    test('battery-backed PRG-NVRAM comes from byte 10 high nibble', () {
      final cartridge = _load(
        _buildNes20Rom(
          prgLsb: 1,
          prgMsb: 0,
          chrLsb: 1,
          chrMsb: 0,
          prgBytes: 0x4000,
          chrBytes: 0x2000,
          byte10: 7 << 4,
          battery: true,
        ),
      );

      expect(cartridge.prgSaveRam.length, 64 << 7);
      expect(cartridge.prgRam, isEmpty);
    });

    test('a battery-backed NES 2.0 cart maps writable save RAM', () {
      final cartridge = _load(
        _buildNes20Rom(
          prgLsb: 1,
          prgMsb: 0,
          chrLsb: 1,
          chrMsb: 0,
          prgBytes: 0x4000,
          chrBytes: 0x2000,
          byte10: 7 << 4,
          battery: true,
        ),
      );

      NES(cartridge: cartridge, eventBus: EventBus());

      cartridge
        ..reset()
        ..cpuWrite(0x6000, 0x42);

      expect(cartridge.prgSaveRam[0], 0x42);
    });

    test('iNES 1.0 RAM sizing is unchanged', () {
      // Byte 10 and byte 11 are not RAM fields in iNES 1.0.
      final rom = _buildRom(chrBanks: 1)
        ..[10] = 0x77
        ..[11] = 0x07;

      final cartridge = _load(rom);

      expect(cartridge.chrRam, isEmpty);
      expect(cartridge.prgRam.length, 0x2000);
      expect(cartridge.prgSaveRam.length, 0x2000);
    });
  });
}
