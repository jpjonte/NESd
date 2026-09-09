import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/fme7_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

import 'fme7_harness.dart';

void main() {
  FME7State roundTrip(FME7State state) {
    final writer = Payload.write();

    state.serialize(writer);

    return MapperState.deserialize(Payload.read(binarize(writer))) as FME7State;
  }

  test('version 0 round-trips every register', () {
    final mapper = buildFme7();

    write(mapper, 0x3, 0x21);
    write(mapper, 0x8, 0xc5);
    write(mapper, 0xa, 0x12);
    write(mapper, 0xc, 0x2);
    write(mapper, 0xe, 0x34);
    write(mapper, 0xf, 0x12);
    write(mapper, 0xd, 0x81);

    final restored = roundTrip(mapper.state);

    expect(restored.chrBanks[3], 0x21);
    expect(restored.prgBanks[1], 0x12);
    expect(restored.workRamBank, 0x05);
    expect(restored.workRamSelected, true);
    expect(restored.workRamEnabled, true);
    expect(restored.arrangement, 0x2);
    expect(restored.irqCounter, 0x1234);
    expect(restored.irqCounterEnabled, true);
    expect(restored.irqEnabled, true);
  });

  test('a restored state re-applies the bank windows', () {
    final mapper = buildFme7();

    write(mapper, 0x9, 3);
    write(mapper, 0x0, 7);

    final restored = buildFme7()..state = roundTrip(mapper.state);

    expect(restored.cpuRead(0x8000), 0xb0 + 3);
    expect(restored.ppuRead(0x0000), 0x10 + 7);
  });

  test('a state written before command C keeps the header arrangement', () {
    final mapper = buildFme7();

    final restored = buildFme7()
      ..state = roundTrip(mapper.state)
      ..ppuWrite(0x2000, 0x11)
      ..ppuWrite(0x2800, 0x22);

    expect(restored.ppuRead(0x2400), 0x11);
    expect(restored.ppuRead(0x2c00), 0x22);
  });
}
