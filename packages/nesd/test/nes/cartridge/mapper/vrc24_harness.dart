import 'dart:typed_data';

import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/vrc24.dart';
import 'package:nesd/nes/cpu/irq_source.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../ui/mocks.dart';

const prgBankCount = 16;

Uint8List buildVrc24Rom({
  required int mapper,
  required int subMapper,
  int chrPages = 512,
  int prgRamSize = 0,
  bool battery = false,
}) {
  const prgSize = prgBankCount * 0x2000;
  final chrSize = chrPages * 0x400;

  final rom = Uint8List(16 + prgSize + chrSize)
    ..setAll(0, [
      0x4e,
      0x45,
      0x53,
      0x1a,
      prgSize ~/ 0x4000,
      chrSize ~/ 0x2000,
      ((mapper & 0x0f) << 4) | (battery ? 0x02 : 0x00),
      (mapper & 0xf0) | 0x08,
      (subMapper << 4) | (mapper >> 8),
      0,
      _ramShift(prgRamSize) | (battery ? 0x70 : 0x00),
    ]);

  const prgStart = 16;
  const chrStart = prgStart + prgSize;

  for (var bank = 0; bank < prgBankCount; bank++) {
    rom[prgStart + bank * 0x2000] = 0xb0 + bank;
  }

  for (var page = 0; page < chrPages; page++) {
    rom[chrStart + page * 0x400] = page & 0xff;
    rom[chrStart + page * 0x400 + 1] = page >> 8;
  }

  return rom;
}

int _ramShift(int size) {
  if (size == 0) {
    return 0;
  }

  var shift = 0;

  while ((64 << shift) < size) {
    shift++;
  }

  return shift;
}

VRC24 buildVrc24({
  int mapper = 23,
  int subMapper = 1,
  int chrPages = 512,
  int prgRamSize = 0,
  bool battery = false,
}) {
  final rom = buildVrc24Rom(
    mapper: mapper,
    subMapper: subMapper,
    chrPages: chrPages,
    prgRamSize: prgRamSize,
    battery: battery,
  );

  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'vrc24-test.nes',
      name: 'vrc24-test.nes',
      type: FilesystemFileType.file,
    ),
    rom,
  )..databaseEntry = null;

  NES(cartridge: cartridge, eventBus: EventBus());

  cartridge.reset();

  return cartridge.mapper as VRC24;
}

void writeRegister(VRC24 mapper, int base, int index, int value) {
  mapper.cpuWrite(base | mapper.variant.registerAddress(index), value);
}

int chrPageAt(VRC24 mapper, int address) =>
    mapper.ppuRead(address) | (mapper.ppuRead(address + 1) << 8);

void selectChr(VRC24 mapper, int slot, int page) {
  final base = 0xb000 + (slot >> 1) * 0x1000;
  final index = (slot & 1) << 1;

  writeRegister(mapper, base, index, page & 0x0f);
  writeRegister(mapper, base, index | 1, page >> 4);
}

bool irqPending(VRC24 mapper) =>
    mapper.bus.cpu.irq & IrqSource.mapper.value != 0;
