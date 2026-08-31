import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/vt/mapper256.dart';
import 'package:nesd/nes/cpu/irq_source.dart';
import 'package:nesd/nes/nes.dart';

import 'vt02_harness.dart';

void clockA12(Mapper256 mapper, NES nes, int count) {
  for (var i = 0; i < count; i++) {
    nes.cpu.cycles += 4;
    mapper.updatePpuAddress(0x0000);
    nes.cpu.cycles += 4;
    mapper.updatePpuAddress(0x1000);
  }
}

void main() {
  group('AD12 clock', () {
    test('fires after the preloaded number of edges', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x410b, 0x00) // TSYNEN = 0, AD12 clock
        ..cpuWrite(0x4101, 3) // preload
        ..cpuWrite(0x4104, 0) // enable
        ..cpuWrite(0x4102, 0); // load and start

      clockA12(mapper, nes, 2);

      expect(nes.cpu.irq & IrqSource.mapper.value, 0);

      clockA12(mapper, nes, 1);

      expect(nes.cpu.irq & IrqSource.mapper.value, isNot(0));
    });

    test('does not fire while disabled', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x410b, 0x00)
        ..cpuWrite(0x4101, 1)
        ..cpuWrite(0x4103, 0) // disable
        ..cpuWrite(0x4102, 0);

      clockA12(mapper, nes, 4);

      expect(nes.cpu.irq & IrqSource.mapper.value, 0);
    });

    test('reloads and fires again', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x410b, 0x00)
        ..cpuWrite(0x4101, 2)
        ..cpuWrite(0x4104, 0)
        ..cpuWrite(0x4102, 0);

      clockA12(mapper, nes, 2);

      expect(nes.cpu.irq & IrqSource.mapper.value, isNot(0));

      nes.bus.cpuWrite(0x4103, 0); // disable clears the pending IRQ

      expect(nes.cpu.irq & IrqSource.mapper.value, 0);

      nes.bus.cpuWrite(0x4104, 0);

      clockA12(mapper, nes, 2);

      expect(nes.cpu.irq & IrqSource.mapper.value, isNot(0));
    });

    test('clears a pending interrupt on disable', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x410b, 0x00)
        ..cpuWrite(0x4101, 1)
        ..cpuWrite(0x4104, 0)
        ..cpuWrite(0x4102, 0);

      clockA12(mapper, nes, 1);

      expect(nes.cpu.irq & IrqSource.mapper.value, isNot(0));

      nes.bus.cpuWrite(0x4103, 0);

      expect(nes.cpu.irq & IrqSource.mapper.value, 0);
    });

    test(r'does not count before $4102 starts it', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x410b, 0x00)
        ..cpuWrite(0x4101, 1)
        ..cpuWrite(0x4104, 0);

      clockA12(mapper, nes, 5);

      expect(nes.cpu.irq & IrqSource.mapper.value, 0);
    });

    test('scanline changes do not clock the timer in AD12 mode', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x410b, 0x00) // TSYNEN = 0, AD12 clock
        ..cpuWrite(0x4101, 2)
        ..cpuWrite(0x4104, 0)
        ..cpuWrite(0x4102, 0);

      nes.ppu.scanline = 1;
      mapper.step();
      nes.ppu.scanline = 2;
      mapper.step();

      expect(
        nes.cpu.irq & IrqSource.mapper.value,
        0,
        reason: 'scanline changes must not clock the timer in AD12 mode',
      );
    });
  });

  group('HSYNC clock', () {
    test('counts scanline changes instead of A12 edges', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x410b, 0x80) // TSYNEN = 1, HSYNC clock
        ..cpuWrite(0x4101, 2)
        ..cpuWrite(0x4104, 0)
        ..cpuWrite(0x4102, 0);

      clockA12(mapper, nes, 5);

      expect(
        nes.cpu.irq & IrqSource.mapper.value,
        0,
        reason: 'A12 edges must not clock the timer in HSYNC mode',
      );

      nes.ppu.scanline = 1;
      mapper.step();
      nes.ppu.scanline = 2;
      mapper.step();

      expect(nes.cpu.irq & IrqSource.mapper.value, isNot(0));
    });

    test('does not fabricate an edge across a clock source toggle', () {
      final (:nes, :mapper) = buildVt02();

      nes.bus
        ..cpuWrite(0x410b, 0x00) // TSYNEN = 0, AD12 clock
        ..cpuWrite(0x4101, 1) // preload
        ..cpuWrite(0x4104, 0) // enable
        ..cpuWrite(0x4102, 0); // load and start

      nes.cpu.cycles += 4;
      mapper.updatePpuAddress(0x0000); // A12 low

      nes.bus.cpuWrite(0x410b, 0x80); // switch to HSYNC

      nes.cpu.cycles += 100000; // a long, unrelated stretch of emulation

      nes.bus.cpuWrite(0x410b, 0x00); // switch back to AD12

      mapper.updatePpuAddress(0x1000); // A12 high

      expect(
        nes.cpu.irq & IrqSource.mapper.value,
        0,
        reason:
            'a stale low-period anchor from before the toggle must not '
            'look like a many-thousand-cycle low period',
      );
    });
  });

  group('state', () {
    test('timer.preload survives a state copy', () {
      final (nes: sourceNes, mapper: source) = buildVt02();

      sourceNes.bus
        ..cpuWrite(0x410b, 0x00) // TSYNEN = 0, AD12 clock
        ..cpuWrite(0x4101, 3) // preload
        ..cpuWrite(0x4104, 0) // enable
        ..cpuWrite(0x4102, 0); // load and start

      final (:nes, :mapper) = buildVt02();

      mapper.state = source.state;

      clockA12(mapper, nes, 3);

      expect(nes.cpu.irq & IrqSource.mapper.value, isNot(0));

      nes.bus
        ..cpuWrite(0x4103, 0) // clear the pending IRQ
        ..cpuWrite(0x4104, 0); // re-enable without reloading

      clockA12(mapper, nes, 3);

      expect(
        nes.cpu.irq & IrqSource.mapper.value,
        isNot(0),
        reason:
            'the second firing only lands on the copied preload; a lost '
            'timer.preload reloads to 0 and takes 256 edges instead',
      );
    });
  });
}
