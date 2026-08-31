import 'package:flutter_test/flutter_test.dart';

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

      expect(nes.bus.cpuRead(0x410c), 0);
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
    test(r'maps the last two PRG banks at $8000 and $C000', () {
      final (:nes, :mapper) = buildVt02();

      expect(mapper.cpuRead(0x8000), vtPrgBanks - 2);
      expect(mapper.cpuRead(0xc000), vtPrgBanks - 1);
    });

    test('maps CHR bank 0', () {
      final (:nes, :mapper) = buildVt02();

      expect(mapper.ppuRead(0x0000), 0);
    });
  });
}
