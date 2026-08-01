import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/tables.dart';

import '../cartridge/mapper/mmc5_harness.dart';

void main() {
  test('the first sample after a reset is averaged over the full window', () {
    final mapper = buildMmc5();
    final apu = mapper.bus.apu..reset();

    mapper.cpuWrite(0x5011, 0xff);

    for (var i = 0; i < 256; i++) {
      apu.step();
      mapper.step();
    }

    expect(apu.sampleIndex, greaterThan(1));

    for (var i = 0; i < apu.sampleIndex; i++) {
      expect(
        apu.sampleBuffer[i],
        closeTo(tndTable[127], 1e-6),
        reason: 'sample $i',
      );
    }
  });
}
