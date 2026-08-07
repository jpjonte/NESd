import 'dart:typed_data';

import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/txsrom.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../ui/mocks.dart';

const txsromPrgBanks = 64;
const txsromChrPages = 256;

Uint8List _buildRom() {
  const prgSize = txsromPrgBanks * 0x2000;
  const chrSize = txsromChrPages * 0x400;

  final rom = Uint8List(16 + prgSize + chrSize)
    ..setAll(0, const [0x4e, 0x45, 0x53, 0x1a, 32, 32, 0x60, 0x70]);

  const prgStart = 16;
  const chrStart = prgStart + prgSize;

  for (var bank = 0; bank < txsromPrgBanks; bank++) {
    rom[prgStart + bank * 0x2000] = bank;
  }

  for (var page = 0; page < txsromChrPages; page++) {
    rom.fillRange(chrStart + page * 0x400, chrStart + (page + 1) * 0x400, page);
  }

  return rom;
}

final _rom = _buildRom();

TxSROM buildTxsrom() {
  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'txsrom-test.nes',
      name: 'txsrom-test.nes',
      type: FilesystemFileType.file,
    ),
    _rom,
  )..databaseEntry = null;

  NES(cartridge: cartridge, eventBus: EventBus());

  return cartridge.mapper as TxSROM;
}
