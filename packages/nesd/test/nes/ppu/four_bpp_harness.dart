import 'dart:typed_data';

import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/nes/ppu/ppu.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../ui/mocks.dart';

Uint8List buildFourBppRom({bool wideLayout = false}) {
  const prgBanks = 2; // 32 KiB
  const prgSize = prgBanks * 0x4000;
  const chrSize = 0x2000;

  final rom = Uint8List(16 + prgSize + chrSize)
    ..setAll(0, [
      0x4e, 0x45, 0x53, 0x1a, //
      prgBanks, 1, 0x00, 0x08, 0x01, 0x00, 0x00, 0x00,
    ]);

  const prgStart = 16;
  const chrStart = prgStart + prgSize;

  rom[prgStart] = 0x4c;
  rom[prgStart + 1] = 0x00;
  rom[prgStart + 2] = 0x80;
  rom[prgStart + prgSize - 4] = 0x00;
  rom[prgStart + prgSize - 3] = 0x80;

  for (var row = 0; row < 8; row++) {
    if (wideLayout) {
      rom[chrStart + 2 * row] = 0xaa;
      rom[chrStart + 2 * row + 1] = 0xf0;
      rom[chrStart + 16 + 2 * row] = 0xcc;
      rom[chrStart + 16 + 2 * row + 1] = 0x00;
    } else {
      rom[chrStart + row] = 0xaa;
      rom[chrStart + 8 + row] = 0xcc;
      rom[chrStart + 16 + row] = 0xf0;
      rom[chrStart + 24 + row] = 0x00;
    }
  }

  return rom;
}

NES buildNes(Uint8List rom) {
  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'four-bpp-test.nes',
      name: 'four-bpp-test.nes',
      type: FilesystemFileType.file,
    ),
    rom,
  )..databaseEntry = null;

  final nes = NES(cartridge: cartridge, eventBus: EventBus());

  cartridge.reset();
  nes.cpu.reset();
  nes.apu.reset();
  nes.ppu.reset();

  return nes;
}

void runFrames(NES nes, int frames) {
  while (nes.ppu.frames < frames) {
    nes.step();
    nes.apu.sampleIndex = 0;
  }
}

int pixelAt(PPU ppu, int x, int y) {
  final pixels = ppu.frameBuffer.presentedPixels;
  final i = (y * 256 + x) * 4;

  return (pixels[i + 3] << 24) |
      (pixels[i + 2] << 16) |
      (pixels[i + 1] << 8) |
      pixels[i];
}

const expectedPattern = [7, 6, 5, 4, 3, 2, 1, 0];
