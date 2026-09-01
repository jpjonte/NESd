import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
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

void main() {
  group('4bpp background', () {
    test('renders 4-bit pixels through the low palette entries', () {
      final nes = buildNes(buildFourBppRom());

      nes.bus.cpuWrite(0x2010, 0x02);

      for (var i = 0; i < 16; i++) {
        nes.bus.ppuWrite(0x3f00 + i, i);
      }

      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      for (var x = 0; x < 8; x++) {
        expect(
          pixelAt(nes.ppu, x, 10),
          nes.ppu.paletteLut[expectedPattern[x]],
          reason: 'x=$x',
        );
      }
    });

    test('attribute bits land at index bits 5-6', () {
      final nes = buildNes(buildFourBppRom());

      nes.bus.cpuWrite(0x2010, 0x02);
      nes.bus.ppuWrite(0x23c0, 0x01); // attr 1 for the top-left quadrant

      for (var i = 0; i < 16; i++) {
        nes.bus.ppuWrite(0x3f20 + i, 0x10 + i);
      }

      nes.bus.ppuWrite(0x3f00, 0x00);
      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      for (var x = 0; x < 8; x++) {
        final pattern = expectedPattern[x];
        final index = pattern == 0 ? 0 : 0x20 | pattern;

        expect(
          pixelAt(nes.ppu, x, 10),
          nes.ppu.paletteLut[index],
          reason: 'x=$x',
        );
      }
    });

    test('the 16-bit-bus layout renders identically', () {
      final nes = buildNes(buildFourBppRom(wideLayout: true));

      nes.bus.cpuWrite(0x2010, 0x42);

      for (var i = 0; i < 16; i++) {
        nes.bus.ppuWrite(0x3f00 + i, i);
      }

      nes.bus.cpuWrite(0x2001, 0x1e);

      runFrames(nes, 2);

      for (var x = 0; x < 8; x++) {
        expect(
          pixelAt(nes.ppu, x, 10),
          nes.ppu.paletteLut[expectedPattern[x]],
          reason: 'x=$x',
        );
      }
    });
  });
}
