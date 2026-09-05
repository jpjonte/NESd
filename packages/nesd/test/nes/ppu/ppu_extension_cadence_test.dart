import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cpu/irq_source.dart';
import 'package:nesd/nes/nes.dart';

import 'four_bpp_harness.dart';

int _cyclesUntilIrq(NES nes) {
  nes.bus
    ..cpuWrite(0x410b, 0x00) // AD12 clock
    ..cpuWrite(0x4101, 10)
    ..cpuWrite(0x4104, 0)
    ..cpuWrite(0x4102, 0);

  nes.bus.cpuWrite(0x2000, 0x08);
  nes.bus.cpuWrite(0x2001, 0x1e);

  while (nes.cpu.irq & IrqSource.mapper.value == 0) {
    nes.step();
    nes.apu.sampleIndex = 0;

    if (nes.ppu.frames > 4) {
      fail('IRQ never fired');
    }
  }

  return nes.ppu.cycles;
}

void main() {
  test('address extension keeps the AD12 timer cadence', () {
    final plain = buildNes(buildEvaRom());
    final extended = buildNes(buildEvaRom());

    extended.bus.cpuWrite(0x2010, 0x18); // BKEXTEN | SPEXTEN

    expect(_cyclesUntilIrq(extended), _cyclesUntilIrq(plain));
  });

  test('4bpp extension keeps the AD12 timer cadence', () {
    final plain = buildNes(buildEvaRom(fourBpp: true));
    final extended = buildNes(buildEvaRom(fourBpp: true));

    plain.bus.cpuWrite(0x2010, 0x06);
    extended.bus.cpuWrite(0x2010, 0x1e);

    expect(_cyclesUntilIrq(extended), _cyclesUntilIrq(plain));
  });
}
