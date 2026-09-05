import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/dma_settings.dart';

import 'vt02_harness.dart';

void main() {
  group('DmaSettings', () {
    test('defaults to a full-page sprite transfer', () {
      final settings = DmaSettings.fromRegister(0x00);

      expect(settings.toPpuData, isFalse);
      expect(settings.start, 0);
      expect(settings.end, 256);
    });

    test('selects video data with bit 0', () {
      final settings = DmaSettings.fromRegister(0x01);

      expect(settings.toPpuData, isTrue);
    });

    test('decodes the four short lengths', () {
      expect(DmaSettings.fromRegister(0x08).end, 16);
      expect(DmaSettings.fromRegister(0x0a).end, 32);
      expect(DmaSettings.fromRegister(0x0c).end, 64);
      expect(DmaSettings.fromRegister(0x0e).end, 128);
    });

    test('treats the unlisted length codes as a full page', () {
      expect(DmaSettings.fromRegister(0x02).end, 256);
      expect(DmaSettings.fromRegister(0x04).end, 256);
      expect(DmaSettings.fromRegister(0x06).end, 256);
    });

    test('takes the start offset from the high nibble', () {
      final settings = DmaSettings.fromRegister(0x30);

      expect(settings.start, 0x30);
    });

    test('stops at 256 rather than wrapping in 256-byte mode', () {
      final settings = DmaSettings.fromRegister(0x30);

      expect(settings.start, 0x30);
      expect(settings.end, 256);
    });

    test('stops at the end of the block containing the start', () {
      final settings = DmaSettings.fromRegister(0x2c);

      expect(settings.start, 0x20);
      expect(settings.end, 0x40);
    });

    test('transfers a whole block when the start is aligned', () {
      final settings = DmaSettings.fromRegister(0x4c);

      expect(settings.start, 0x40);
      expect(settings.end, 0x80);
    });
  });

  group('transfer', () {
    test('writes sprite data into OAM', () {
      final (:nes, :mapper) = buildVt02();

      for (var i = 0; i < 256; i++) {
        nes.bus.cpuWrite(0x0300 + i, i);
      }

      nes.bus
        ..cpuWrite(0x4034, 0x00) // sprite, 256 bytes, start 0
        ..cpuWrite(0x4014, 0x03);

      nes.cpu.step();

      expect(nes.ppu.oam[0], 0);
      expect(nes.ppu.oam[255], 255);
    });

    test('honours the block stop in 64-byte mode', () {
      final (:nes, :mapper) = buildVt02();

      for (var i = 0; i < 256; i++) {
        nes.bus.cpuWrite(0x0300 + i, i);
      }

      nes.bus
        ..cpuWrite(0x4034, 0x2c) // sprite, 64 bytes, start $20
        ..cpuWrite(0x4014, 0x03);

      nes.cpu.step();

      expect(nes.ppu.oam[0], 0x20);
      expect(nes.ppu.oam[31], 0x3f);
      expect(nes.ppu.oam[32], 0);
    });

    test('writes video data through PPUDATA instead of OAM', () {
      final (:nes, :mapper) = buildVt02();

      for (var i = 0; i < 32; i++) {
        nes.bus.cpuWrite(0x0300 + i, i);
      }

      nes.bus
        ..cpuWrite(0x2006, 0x3f) // PPUADDR high: target the palette
        ..cpuWrite(0x2006, 0x00) // PPUADDR low: $3F00
        ..cpuWrite(0x4034, 0x0b) // video, 32 bytes, start 0
        ..cpuWrite(0x4014, 0x03);

      nes.cpu.step();

      expect(nes.ppu.palette[1], 1);
      expect(nes.ppu.palette[31], 31);
      expect(nes.ppu.oam[0], 0);
    });
  });

  group('reset', () {
    test('restores default DMA settings for a later transfer', () {
      final (:nes, :mapper) = buildVt02();

      for (var i = 0; i < 256; i++) {
        nes.bus.cpuWrite(0x0300 + i, i);
      }

      nes.bus.cpuWrite(0x4034, 0x2c); // sprite, 64 bytes, start $20

      mapper.reset();

      nes.bus.cpuWrite(0x4014, 0x03);

      nes.cpu.step();

      expect(nes.ppu.oam[0], 0);
      expect(nes.ppu.oam[255], 255);
    });
  });

  group('state', () {
    test('a state copy restores non-default DMA settings', () {
      final (nes: sourceNes, mapper: source) = buildVt02();

      sourceNes.bus.cpuWrite(0x4034, 0x2c); // sprite, 64 bytes, start $20

      final (:nes, :mapper) = buildVt02();

      mapper.state = source.state;

      for (var i = 0; i < 256; i++) {
        nes.bus.cpuWrite(0x0300 + i, i);
      }

      nes.bus.cpuWrite(0x4014, 0x03);

      nes.cpu.step();

      expect(nes.ppu.oam[0], 0x20);
      expect(nes.ppu.oam[31], 0x3f);
      expect(nes.ppu.oam[32], 0);
    });
  });
}
