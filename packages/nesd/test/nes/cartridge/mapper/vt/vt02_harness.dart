import 'dart:typed_data';

import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/vt/mapper256.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../../ui/mocks.dart';

/// PRG-ROM size, multiples of 16 KB
const vtPrgBanks = 8;

/// CHR-ROM size, multiples of 8 KB
const vtChrPages = 8;

Uint8List _buildRom(int prgBanks, int chrPages, int subMapperId) {
  final prgSize = prgBanks * 0x4000;
  final chrSize = chrPages * 0x2000;

  final rom = Uint8List(16 + prgSize + chrSize)
    ..setAll(0, [
      0x4e, 0x45, 0x53, 0x1a, //
      prgBanks & 0xff, chrPages & 0xff, 0x00, 0x08,
      (subMapperId << 4) | 0x01,
      ((chrPages >> 8) << 4) | (prgBanks >> 8), 0x00, 0x00,
    ]);

  const prgStart = 16;
  final chrStart = prgStart + prgSize;

  _stampBanks(rom, prgStart, prgSize, 0x2000);
  _stampBanks(rom, chrStart, chrSize, 0x400);

  return rom;
}

void _stampBanks(Uint8List rom, int start, int size, int bankSize) {
  for (var bank = 0; bank < size ~/ bankSize; bank++) {
    final offset = start + bank * bankSize;

    rom[offset] = bank & 0xff;
    rom[offset + 1] = bank >> 8;
  }
}

final _roms = <(int, int, int), Uint8List>{};

({NES nes, Mapper256 mapper}) buildVt02({
  int prgBanks = vtPrgBanks,
  int chrPages = vtChrPages,
  int subMapperId = 0,
}) {
  final rom = _roms[(prgBanks, chrPages, subMapperId)] ??= _buildRom(
    prgBanks,
    chrPages,
    subMapperId,
  );

  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'vt02-test.nes',
      name: 'vt02-test.nes',
      type: FilesystemFileType.file,
    ),
    rom,
  )..databaseEntry = null;

  final nes = NES(cartridge: cartridge, eventBus: EventBus());

  cartridge.reset();

  return (nes: nes, mapper: cartridge.mapper as Mapper256);
}

void clockA12(Mapper256 mapper, NES nes, int count) {
  nes.ppu.PPUMASK = 0x18;

  for (var i = 0; i < count; i++) {
    nes.cpu.cycles += 4;
    mapper.updatePpuAddress(0x0000);
    nes.cpu.cycles += 4;
    mapper.updatePpuAddress(0x1000);
  }
}
