import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'unrom512_flash_commands.dart';
import 'unrom512_harness.dart';

void main() {
  group('harness header parsing', () {
    test('the harness header parses as mapper 30', () {
      final mapper = buildUnrom512();

      expect(mapper.id, 30);
    });

    test('the harness allocates 32 KiB of CHR-RAM', () {
      final mapper = buildUnrom512();

      expect(mapper.cartridge.chrRam.length, 0x8000);
    });

    test('a header declaring 8 KiB of CHR-RAM is widened to 32 KiB', () {
      final mapper = buildUnrom512(chrRamShift: 7);

      expect(mapper.cartridge.chrRam.length, 0x8000);
    });
  });

  group('register range', () {
    test('a flashable board does not latch writes below \$c000', () {
      final mapper = buildUnrom512(battery: true)..cpuWrite(0x9000, 0x05);

      expect(mapper.cpuRead(0x8000), 0);
    });

    test('a flashable board latches writes at \$c000 and above', () {
      final mapper = buildUnrom512(battery: true)..cpuWrite(0xc000, 0x05);

      expect(mapper.cpuRead(0x8000), 5);
    });

    test('submapper 1 does not latch writes below \$c000', () {
      final mapper = buildUnrom512(subMapper: 1)..cpuWrite(0x9000, 0x05);

      expect(mapper.cpuRead(0x8000), 0);
    });

    test('a bus-conflict board latches writes below \$c000', () {
      final mapper = buildUnrom512()
        ..cpuWrite(0xc000, 0x03) // bank 3, whose contents are $03
        ..cpuWrite(0x8000, 0x02);

      expect(mapper.cpuRead(0x8000), 2);
    });

    test('submapper 2 latches writes below \$c000', () {
      final mapper = buildUnrom512(subMapper: 2)
        ..cpuWrite(0xc000, 0x03)
        ..cpuWrite(0x8000, 0x02);

      expect(mapper.cpuRead(0x8000), 2);
    });
  });

  group('bus conflicts', () {
    test('submapper 0 without a battery masks writes with ROM contents', () {
      final mapper = buildUnrom512()
        ..cpuWrite(0xc000, 0x03) // bank 3, whose contents are $03
        ..cpuWrite(0x8000, 0x07);

      expect(mapper.cpuRead(0x8000), 3);
    });

    test('submapper 2 masks writes with ROM contents', () {
      final mapper = buildUnrom512(subMapper: 2)
        ..cpuWrite(0xc000, 0x03)
        ..cpuWrite(0x8000, 0x07);

      expect(mapper.cpuRead(0x8000), 3);
    });

    test('a bus conflict also masks the CHR bank bits', () {
      final mapper = buildUnrom512()
        ..ppuWrite(0x0000, 0x42)
        ..cpuWrite(0xc000, 0x60);

      expect(mapper.ppuRead(0x0000), 0x42);
    });

    test('a flashable board applies the CHR bank bits unmasked', () {
      final mapper = buildUnrom512(battery: true)
        ..ppuWrite(0x0000, 0x42)
        ..cpuWrite(0xc000, 0x60);

      expect(mapper.ppuRead(0x0000), 0);
    });

    test('submapper 1 applies the CHR bank bits unmasked', () {
      final mapper = buildUnrom512(subMapper: 1)
        ..ppuWrite(0x0000, 0x42)
        ..cpuWrite(0xc000, 0x60);

      expect(mapper.ppuRead(0x0000), 0);
    });
  });

  group('PRG banking', () {
    test('the switchable window selects the latched bank', () {
      final mapper = buildUnrom512(battery: true)..cpuWrite(0xc000, 5);

      expect(mapper.cpuRead(0x8000), 5);
    });

    test('the switchable window starts on bank 0', () {
      final mapper = buildUnrom512(battery: true);

      expect(mapper.cpuRead(0x8000), 0);
    });

    test('the fixed window always reads the last bank', () {
      final mapper = buildUnrom512(battery: true)..cpuWrite(0xc000, 5);

      expect(mapper.cpuRead(0xc000), unrom512PrgBanks - 1);
    });

    test('only the low five bits select the PRG bank', () {
      final mapper = buildUnrom512(battery: true)..cpuWrite(0xc000, 0xe9);

      expect(mapper.cpuRead(0x8000), 9);
    });
  });

  group('CHR-RAM banking', () {
    test('a CHR bank selection isolates the banks', () {
      final mapper = buildUnrom512(battery: true)
        ..ppuWrite(0x0000, 0x42)
        ..cpuWrite(0xc000, 0x20); // CHR bank 1

      expect(mapper.ppuRead(0x0000), 0);
    });

    test('switching back to a CHR bank restores its contents', () {
      final mapper = buildUnrom512(battery: true)
        ..ppuWrite(0x0000, 0x42)
        ..cpuWrite(0xc000, 0x20) // CHR bank 1
        ..cpuWrite(0xc000, 0x00); // CHR bank 0

      expect(mapper.ppuRead(0x0000), 0x42);
    });

    test('all four CHR banks are distinct', () {
      final mapper = buildUnrom512(battery: true);

      for (var bank = 0; bank < 4; bank++) {
        mapper
          ..cpuWrite(0xc000, bank << 5)
          ..ppuWrite(0x0000, 0xa0 | bank);
      }

      for (var bank = 0; bank < 4; bank++) {
        mapper.cpuWrite(0xc000, bank << 5);

        expect(mapper.ppuRead(0x0000), 0xa0 | bank);
      }
    });
  });

  group('mirroring', () {
    test('a header without the four-screen bit gives vertical arrangement', () {
      final mapper = buildUnrom512(battery: true)..ppuWrite(0x2000, 0x11);

      expect(mapper.ppuRead(0x2400), 0x11);
      expect(mapper.ppuRead(0x2800), isNot(0x11));
    });

    test('a header with bit 0 set gives horizontal arrangement', () {
      final mapper = buildUnrom512(battery: true, horizontalArrangement: true)
        ..ppuWrite(0x2000, 0x11);

      expect(mapper.ppuRead(0x2800), 0x11);
      expect(mapper.ppuRead(0x2400), isNot(0x11));
    });

    test('fixed mirroring ignores bit 7 of the latch', () {
      final mapper = buildUnrom512(battery: true)
        ..ppuWrite(0x2000, 0x11)
        ..cpuWrite(0xc000, 0x80);

      expect(mapper.ppuRead(0x2400), 0x11);
      expect(mapper.ppuRead(0x2800), isNot(0x11));
    });

    test('the four-screen bit selects one-screen mirroring', () {
      final mapper = buildUnrom512(battery: true, fourScreen: true)
        ..ppuWrite(0x2000, 0x11);

      expect(mapper.ppuRead(0x2400), 0x11);
      expect(mapper.ppuRead(0x2800), 0x11);
      expect(mapper.ppuRead(0x2c00), 0x11);
    });

    test('bit 7 clear selects the lower one-screen page', () {
      final mapper = buildUnrom512(battery: true, fourScreen: true)
        ..cpuWrite(0xc000, 0x80)
        ..ppuWrite(0x2000, 0x22)
        ..cpuWrite(0xc000, 0x00)
        ..ppuWrite(0x2000, 0x11);

      expect(mapper.ppuRead(0x2000), 0x11);
    });

    test('bit 7 set selects the upper one-screen page', () {
      final mapper = buildUnrom512(battery: true, fourScreen: true)
        ..cpuWrite(0xc000, 0x00)
        ..ppuWrite(0x2000, 0x11)
        ..cpuWrite(0xc000, 0x80);

      expect(mapper.ppuRead(0x2000), isNot(0x11));
    });

    test('the one-screen page switch preserves both pages', () {
      final mapper = buildUnrom512(battery: true, fourScreen: true)
        ..cpuWrite(0xc000, 0x00)
        ..ppuWrite(0x2000, 0x11)
        ..cpuWrite(0xc000, 0x80)
        ..ppuWrite(0x2000, 0x22)
        ..cpuWrite(0xc000, 0x00);

      expect(mapper.ppuRead(0x2000), 0x11);
    });

    test('submapper 3 selects vertical arrangement with bit 7 clear', () {
      final mapper = buildUnrom512(subMapper: 3)
        ..cpuWrite(0xc000, 0x00)
        ..ppuWrite(0x2000, 0x11);

      expect(mapper.ppuRead(0x2400), 0x11);
      expect(mapper.ppuRead(0x2800), isNot(0x11));
    });

    test('submapper 3 selects horizontal arrangement with bit 7 set', () {
      final mapper = buildUnrom512(subMapper: 3)
        ..cpuWrite(0xc000, 0x00)
        ..ppuWrite(0x2000, 0x11)
        ..cpuWrite(0xc000, 0x80);

      expect(mapper.ppuRead(0x2800), 0x11);
      expect(mapper.ppuRead(0x2400), isNot(0x11));
    });

    test('a four-screen header falls back to the header arrangement', () {
      final mapper = buildUnrom512(
        battery: true,
        fourScreen: true,
        horizontalArrangement: true,
      )..ppuWrite(0x2000, 0x11);

      expect(mapper.ppuRead(0x2800), 0x11);
      expect(mapper.ppuRead(0x2400), isNot(0x11));
    });
  });

  group('flash', () {
    test('an erased sector reads as \$ff', () {
      final mapper = buildUnrom512(battery: true);

      eraseFlashSector(mapper, bank: 5, address: 0x8000);

      expect(mapper.cpuRead(0x8000), 0xff);
    });

    test('an erase only clears its own 4 KiB sector', () {
      final mapper = buildUnrom512(battery: true);

      eraseFlashSector(mapper, bank: 5, address: 0x8000);

      expect(mapper.cpuRead(0x8fff), 0xff);
      expect(mapper.cpuRead(0x9000), 5);
    });

    test('a programmed byte reads back', () {
      final mapper = buildUnrom512(battery: true);

      eraseFlashSector(mapper, bank: 5, address: 0x8000);
      programFlashByte(mapper, bank: 5, address: 0x8000, value: 0x42);

      expect(mapper.cpuRead(0x8000), 0x42);
    });

    test('programming only clears bits', () {
      final mapper = buildUnrom512(battery: true);

      programFlashByte(mapper, bank: 5, address: 0x8000, value: 0x06);

      expect(mapper.cpuRead(0x8000), 0x04);
    });

    test('programming only touches the addressed byte', () {
      final mapper = buildUnrom512(battery: true);

      programFlashByte(mapper, bank: 5, address: 0x8000, value: 0x00);

      expect(mapper.cpuRead(0x8001), 5);
    });

    test('a program without the unlock sequence is ignored', () {
      final mapper = buildUnrom512(battery: true)
        ..cpuWrite(0xc000, 0x01)
        ..cpuWrite(0x9555, 0xa0)
        ..cpuWrite(0xc000, 0x05)
        ..cpuWrite(0x8000, 0x00);

      expect(mapper.cpuRead(0x8000), 5);
    });

    test('a lone data write is ignored', () {
      final mapper = buildUnrom512(battery: true)
        ..cpuWrite(0xc000, 0x05)
        ..cpuWrite(0x8000, 0x00);

      expect(mapper.cpuRead(0x8000), 5);
    });

    test('a chip erase clears every bank', () {
      final mapper = buildUnrom512(battery: true);

      unlockFlash(mapper);

      mapper
        ..cpuWrite(0xc000, 0x01)
        ..cpuWrite(0x9555, 0x80);

      unlockFlash(mapper);

      mapper
        ..cpuWrite(0xc000, 0x01)
        ..cpuWrite(0x9555, 0x10)
        ..cpuWrite(0xc000, 0x07);

      expect(mapper.cpuRead(0x8000), 0xff);
    });

    test('a board without a battery never writes its ROM', () {
      final mapper = buildUnrom512();

      programFlashByte(mapper, bank: 5, address: 0x8000, value: 0x00);

      expect(mapper.cartridge.prgRom[5 * 0x4000], 5);
    });

    test('submapper 2 never writes its ROM', () {
      final mapper = buildUnrom512(subMapper: 2);

      programFlashByte(mapper, bank: 5, address: 0x8000, value: 0x00);

      expect(mapper.cartridge.prgRom[5 * 0x4000], 5);
    });

    test('flashing leaves the pristine ROM image untouched', () {
      final mapper = buildUnrom512(battery: true);

      programFlashByte(mapper, bank: 5, address: 0x8000, value: 0x00);

      expect(mapper.cartridge.rom[16 + 5 * 0x4000], 5);
    });
  });

  group('save states', () {
    test('a save state restores the latch', () {
      final mapper = buildUnrom512(battery: true)..cpuWrite(0xc000, 0x09);

      final state = mapper.state;

      mapper
        ..cpuWrite(0xc000, 0x11)
        ..state = state;

      expect(mapper.cpuRead(0x8000), 9);
    });

    test('a save state restores flashed contents', () {
      final mapper = buildUnrom512(battery: true);

      programFlashByte(mapper, bank: 5, address: 0x8000, value: 0x04);

      final state = mapper.state;

      mapper.state = state;

      expect(mapper.cpuRead(0x8000), 4);
    });

    test('restoring a state rolls back later flash writes', () {
      final mapper = buildUnrom512(battery: true);

      programFlashByte(mapper, bank: 5, address: 0x8000, value: 0x04);

      final state = mapper.state;

      programFlashByte(mapper, bank: 6, address: 0x8000, value: 0x02);

      mapper
        ..state = state
        ..cpuWrite(0xc000, 6);

      expect(mapper.cpuRead(0x8000), 6);
    });

    test('restoring a state keeps the flash writes it captured', () {
      final mapper = buildUnrom512(battery: true);

      programFlashByte(mapper, bank: 5, address: 0x8000, value: 0x04);

      final state = mapper.state;

      programFlashByte(mapper, bank: 6, address: 0x8000, value: 0x02);

      mapper
        ..state = state
        ..cpuWrite(0xc000, 5);

      expect(mapper.cpuRead(0x8000), 4);
    });

    test('an untouched flash contributes no sectors to the state', () {
      final mapper = buildUnrom512(battery: true);

      expect(mapper.state.flashSectors, isEmpty);
    });

    test('a state carries one sector per flashed sector', () {
      final mapper = buildUnrom512(battery: true);

      programFlashByte(mapper, bank: 5, address: 0x8000, value: 0x04);

      expect(mapper.state.flashSectors, hasLength(1));
    });
  });

  group('battery save', () {
    test('a flashed board saves its overlay', () {
      final mapper = buildUnrom512(battery: true);

      programFlashByte(mapper, bank: 5, address: 0x8000, value: 0x04);

      expect(mapper.save(), isNotNull);
    });

    test('an untouched flash saves nothing', () {
      final mapper = buildUnrom512(battery: true);

      expect(mapper.save(), isNull);
    });

    test('a board without flash saves nothing', () {
      final mapper = buildUnrom512();

      expect(mapper.save(), isNull);
    });

    test('a battery file that is not a flash overlay is ignored', () {
      final mapper = buildUnrom512(battery: true)
        ..load(Uint8List.fromList([1, 2, 3, 4]));

      expect(mapper.cpuRead(0x8000), 0);
    });

    test('a battery save restores flashed contents', () {
      final source = buildUnrom512(battery: true);

      programFlashByte(source, bank: 5, address: 0x8000, value: 0x04);

      final restored = buildUnrom512(battery: true)
        ..load(source.save()!)
        ..cpuWrite(0xc000, 5);

      expect(restored.cpuRead(0x8000), 4);
    });
  });

  group('software identify', () {
    test('reports the SST manufacturer code at even addresses', () {
      final mapper = buildUnrom512(battery: true);

      enterFlashSoftwareId(mapper);

      expect(mapper.cpuRead(0x8000), 0xbf);
    });

    test('reports the 512 KiB device code at odd addresses', () {
      final mapper = buildUnrom512(battery: true);

      enterFlashSoftwareId(mapper);

      expect(mapper.cpuRead(0x8001), 0xb7);
    });

    test('reports the 128 KiB device code on a smaller chip', () {
      final mapper = buildUnrom512(battery: true, prgBanks: 8);

      enterFlashSoftwareId(mapper);

      expect(mapper.cpuRead(0x8001), 0xb5);
    });

    test('reports the 256 KiB device code on a mid-sized chip', () {
      final mapper = buildUnrom512(battery: true, prgBanks: 16);

      enterFlashSoftwareId(mapper);

      expect(mapper.cpuRead(0x8001), 0xb6);
    });

    test('a read-reset command returns to reading the ROM', () {
      final mapper = buildUnrom512(battery: true);

      enterFlashSoftwareId(mapper);
      exitFlashSoftwareId(mapper);

      expect(mapper.cpuRead(0x8000), 1);
    });

    test('the fixed window keeps reading the ROM', () {
      final mapper = buildUnrom512(battery: true);

      enterFlashSoftwareId(mapper);

      expect(mapper.cpuRead(0xc000), unrom512PrgBanks - 1);
    });

    test('a board without flash never identifies', () {
      final mapper = buildUnrom512();

      enterFlashSoftwareId(mapper);

      expect(mapper.cpuRead(0x8000), isNot(0xbf));
    });
  });
}
