import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';
import 'package:nesd/nes/cartridge/mapper/vrc24_state.dart';

import 'vrc24_harness.dart';

void main() {
  VRC24State roundTrip(VRC24State state) {
    final writer = Payload.write();

    state.serialize(writer);

    return MapperState.deserialize(Payload.read(binarize(writer)))
        as VRC24State;
  }

  test('version 0 round-trips every register', () {
    final mapper = buildVrc24(prgRamSize: 0x2000)
      ..cpuWrite(0x8000, 0x15)
      ..cpuWrite(0xa000, 0x0a)
      ..cpuWrite(0x9000, 0x03);

    selectChr(mapper, 5, 0x1a5);

    writeRegister(mapper, 0x9000, 2, 0x02);
    writeRegister(mapper, 0xf000, 0, 0x4);
    writeRegister(mapper, 0xf000, 1, 0xa);
    writeRegister(mapper, 0xf000, 2, 0x03);

    for (var i = 0; i < 10; i++) {
      mapper.step();
    }

    final restored = roundTrip(mapper.state);

    expect(restored.id, 23);
    expect(restored.prgBanks, [0x15, 0x0a]);
    expect(restored.chrBanks[5], 0x1a5);
    expect(restored.mirroring, 3);
    expect(restored.swapMode, true);
    expect(restored.workRamEnabled, false);
    expect(restored.irqLatch, 0xa4);
    expect(restored.irqCounter, 0xa4);
    expect(restored.irqPrescaler, 341 - 30);
    expect(restored.irqEnabled, true);
    expect(restored.irqEnableAfterAck, true);
    expect(restored.irqCycleMode, false);
  });

  test('the prescaler round-trips after a wrap', () {
    final mapper = buildVrc24();

    writeRegister(mapper, 0xf000, 2, 0x02);

    for (var i = 0; i < 114; i++) {
      mapper.step();
    }

    expect(roundTrip(mapper.state).irqPrescaler, 340);
  });

  test(r'the $6000 latch round-trips', () {
    final mapper = buildVrc24()..cpuWrite(0x6000, 1);

    expect(roundTrip(mapper.state).latch, 1);
  });

  test('a restored state re-applies the bank windows', () {
    final mapper = buildVrc24(prgRamSize: 0x2000)
      ..cpuWrite(0x8000, 3)
      ..cpuWrite(0x9000, 0);

    selectChr(mapper, 0, 7);

    writeRegister(mapper, 0x9000, 2, 0x02);

    final restored = buildVrc24(prgRamSize: 0x2000)
      ..state = roundTrip(mapper.state)
      ..ppuWrite(0x2000, 0x11)
      ..ppuWrite(0x2400, 0x22);

    expect(restored.cpuRead(0xc000), 0xb0 + 3);
    expect(restored.cpuRead(0x8000), 0xb0 + prgBankCount - 2);
    expect(chrPageAt(restored, 0x0000), 7);
    expect(restored.ppuRead(0x2800), 0x11);
    expect(restored.ppuRead(0x2c00), 0x22);
    expect(restored.cpuRead(0x6000), 0);
  });

  test('a state written before any mirroring write keeps the header', () {
    final mapper = buildVrc24();

    final restored = buildVrc24()
      ..state = roundTrip(mapper.state)
      ..ppuWrite(0x2000, 0x11)
      ..ppuWrite(0x2800, 0x22);

    expect(restored.ppuRead(0x2400), 0x11);
    expect(restored.ppuRead(0x2c00), 0x22);
  });

  test('a restored IRQ counter keeps counting', () {
    final mapper = buildVrc24();

    writeRegister(mapper, 0xf000, 0, 0xf);
    writeRegister(mapper, 0xf000, 1, 0xf);
    writeRegister(mapper, 0xf000, 2, 0x06);

    final restored = buildVrc24()..state = roundTrip(mapper.state);

    expect(irqPending(restored), false);

    restored.step();

    expect(irqPending(restored), true);
  });

  test('the state carries the mapper id of its board', () {
    final writer = Payload.write();

    buildVrc24(mapper: 22, subMapper: 0).state.serialize(writer);

    final bytes = binarize(writer);

    expect(MapperState.peekId(bytes), 22);
    expect(MapperState.deserialize(Payload.read(bytes)).id, 22);
  });
}
