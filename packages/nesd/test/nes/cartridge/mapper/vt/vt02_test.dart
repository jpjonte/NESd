import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/region.dart';

import 'vt02_harness.dart';

void main() {
  group('system registers', () {
    test('store and read back through the bus', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x410e, 0xa5)
        ..cpuWrite(0x410f, 0x5a);

      expect(nes.bus.cpuRead(0x410e), 0xa5);
      expect(nes.bus.cpuRead(0x410f), 0x5a);
    });

    test('retain the program bank registers', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x4107, 0x11)
        ..cpuWrite(0x4108, 0x22)
        ..cpuWrite(0x4109, 0x33)
        ..cpuWrite(0x410a, 0x44);

      expect(mapper.registerAt(0x4107), 0x11);
      expect(mapper.registerAt(0x4108), 0x22);
      expect(mapper.registerAt(0x4109), 0x33);
      expect(mapper.registerAt(0x410a), 0x44);
    });

    test('ignore undocumented addresses', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x410c, 0xff);

      expect(mapper.registerAt(0x410c), 0);
      expect(nes.bus.cpuRead(0x410c), 0xff, reason: 'open bus');
    });
  });

  group('graphics registers', () {
    test('store the extended control registers', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x2010, 0x81)
        ..cpuWrite(0x2011, 0x0c);

      expect(mapper.registerAt(0x2010), 0x81);
      expect(mapper.registerAt(0x2011), 0x0c);
    });

    test('store the six video bank registers', () {
      final (:nes, :mapper) = buildVt02();

      for (var i = 0; i < 6; i++) {
        nes.bus.cpuWrite(0x2012 + i, 0x10 + i);
      }

      for (var i = 0; i < 6; i++) {
        expect(mapper.registerAt(0x2012 + i), 0x10 + i);
      }
    });

    test('mirror every 32 bytes across the PPU range', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x2030, 0x11);

      expect(mapper.registerAt(0x2010), 0x11);

      nes.bus.cpuWrite(0x2050, 0x22);

      expect(mapper.registerAt(0x2010), 0x22);

      nes.bus.cpuWrite(0x3ff0, 0x33);

      expect(mapper.registerAt(0x2010), 0x33);
    });

    test(r'ignore $2008-$200F', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x2008, 0xff);

      expect(nes.bus.cpuRead(0x2008), 0);
    });

    test(r'ignore the undocumented $201B', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x201b, 0xff);

      expect(mapper.registerAt(0x201b), 0);
      expect(nes.bus.cpuRead(0x201b), 0);
    });

    test(r'leave $2000-$2007 with the stock PPU', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x2003, 0x42);

      expect(nes.ppu.OAMADDR, 0x42);
    });

    test('read gun ports as zero', () {
      final (:nes, :mapper) = buildVt02();

      expect(nes.bus.cpuRead(0x201c), 0);
      expect(nes.bus.cpuRead(0x201d), 0);
      expect(nes.bus.cpuRead(0x201e), 0);
      expect(nes.bus.cpuRead(0x201f), 0);
    });

    test('accept the gun port reset without effect', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x2019, 0xff);

      expect(nes.bus.cpuRead(0x201c), 0);
    });
  });

  group('reset', () {
    test('clears every register', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x4107, 0xff)
        ..cpuWrite(0x2010, 0xff)
        ..cpuWrite(0x4035, 0xff);

      mapper.reset();

      expect(mapper.registerAt(0x4107), 0);
      expect(mapper.registerAt(0x2010), 0);
      expect(nes.bus.cpuRead(0x4035), 0);
    });
  });

  group('mapper 256', () {
    test('maps CHR bank 0', () {
      final (:nes, :mapper) = buildVt02();

      expect(mapper.ppuRead(0x0000), 0);
    });
  });

  group('RS232', () {
    test('reports transmission as complete so polling loops exit', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x411a, 0x41);

      expect(nes.bus.cpuRead(0x4119) & 0x40, 0x40, reason: 'TIFLAG');
    });

    test('never reports received data', () {
      final (:nes, :mapper) = buildVt02();

      final flags = nes.bus.cpuRead(0x4119);

      expect(flags & 0x80, 0, reason: 'RIFLAG');
      expect(flags & 0x20, 0, reason: 'RINGF');
      expect(flags & 0x02, 0, reason: 'RERRF');
      expect(nes.bus.cpuRead(0x411b), 0, reason: 'RX data');
    });

    test(r'does not echo writes back on $411B', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x411b, 0x77);

      expect(nes.bus.cpuRead(0x411b), 0);
    });

    test('reports NTSC in the region bits', () {
      final (:nes, :mapper) = buildVt02();

      nes.region = Region.ntsc;

      final flags = nes.bus.cpuRead(0x4119);

      expect(flags & 0x08, 0, reason: 'XPORN: 0 is NTSC');
      expect(flags & 0x10, 0, reason: 'XF5OR6: 0 is 60Hz');
    });

    test('reports PAL in the region bits', () {
      final (:nes, :mapper) = buildVt02();

      nes.region = Region.pal;

      final flags = nes.bus.cpuRead(0x4119);

      expect(flags & 0x08, 0x08, reason: 'XPORN: 1 is PAL');
      expect(flags & 0x10, 0x10, reason: 'XF5OR6: 1 is 50Hz');
    });

    test('stores the baud divisor', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x4114, 0x67)
        ..cpuWrite(0x4115, 0x05);

      expect(mapper.registerAt(0x4114), 0x67);
      expect(mapper.registerAt(0x4115), 0x05);
    });
  });

  group('I/O ports', () {
    test('store direction and data', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x410d, 0xaa)
        ..cpuWrite(0x410e, 0x5a)
        ..cpuWrite(0x410f, 0xa5);

      expect(mapper.registerAt(0x410d), 0xaa);
      expect(nes.bus.cpuRead(0x410e), 0x5a);
      expect(nes.bus.cpuRead(0x410f), 0xa5);
    });
  });

  group('mirroring', () {
    test(r'$4106 bit 0 selects the nametable arrangement', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x4106, 0);
      mapper.ppuWrite(0x2000, 0x11);

      expect(mapper.ppuRead(0x2800), 0x11);

      nes.bus.cpuWrite(0x4106, 1);
      mapper.ppuWrite(0x2000, 0x22);

      expect(mapper.ppuRead(0x2400), 0x22);
    });

    test(
      'reset selects the horizontal arrangement regardless of the header',
      () {
        final (:nes, :mapper) = buildVt02();

        expect(
          nes.bus.cartridge.nametableLayout,
          NametableLayout.vertical,
          reason: 'the header must disagree with the register default',
        );

        nes.bus.cpuWrite(0x4106, 1);

        mapper
          ..reset()
          ..ppuWrite(0x2000, 0x33);

        expect(mapper.ppuRead(0x2800), 0x33);
      },
    );

    test(r'restoring a state applies its $4106 arrangement', () {
      final (nes: sourceNes, mapper: source) = buildVt02();

      sourceNes.bus.cpuWrite(0x4106, 0);

      final (:nes, :mapper) = buildVt02();

      nes.bus.cpuWrite(0x4106, 1);

      mapper
        ..state = source.state
        ..ppuWrite(0x2000, 0x44);

      expect(mapper.ppuRead(0x2800), 0x44);
    });
  });
}
