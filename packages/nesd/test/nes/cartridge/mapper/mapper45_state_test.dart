import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/mapper45_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';
import 'package:nesd/nes/cartridge/mapper/mmc3_state.dart';

import 'mapper45_harness.dart';

void main() {
  Mapper45State roundTrip(Mapper45State state) {
    final writer = Payload.write();

    state.serialize(writer);

    return MapperState.deserialize(Payload.read(binarize(writer)))
        as Mapper45State;
  }

  test('round-trips the MMC3 and outer registers', () {
    final mapper = buildMapper45()
      ..cpuWrite(0x6000, 0x12)
      ..cpuWrite(0x6000, 0x34)
      ..cpuWrite(0x6000, 0x0f)
      ..cpuWrite(0x8000, 6)
      ..cpuWrite(0x8001, 0x21)
      ..cpuWrite(0xc000, 0x42);

    final restored = roundTrip(mapper.state);

    expect(restored.id, 45);
    expect(restored.outer0, 0x12);
    expect(restored.outer1, 0x34);
    expect(restored.outer2, 0x0f);
    expect(restored.outer3, 0);
    expect(restored.writeIndex, 3);
    expect(restored.r6, 0x21);
    expect(restored.irqLatch, 0x42);
  });

  test('round-trips the lock bit', () {
    final mapper = buildMapper45()
      ..cpuWrite(0x6000, 0x00)
      ..cpuWrite(0x6000, 0x00)
      ..cpuWrite(0x6000, 0x0f)
      ..cpuWrite(0x6000, 0x40);

    expect(mapper.locked, isTrue);

    final target = buildMapper45()..state = roundTrip(mapper.state);

    expect(target.outerRegisters[3], 0x40);
    expect(target.locked, isTrue);
  });

  test('restoring re-maps the windows', () {
    final source = buildMapper45()
      ..cpuWrite(0x6000, 0x00)
      ..cpuWrite(0x6000, 0x40);

    final target = buildMapper45()..state = source.state;

    expect(target.cpuRead(0xe000), 0x7f);
    expect(target.writeIndex, 2);
  });

  test('restoring overwrites live fields that differ from the saved '
      'state', () {
    final target = buildMapper45();
    target.outerRegisters
      ..[0] = 0x10
      ..[1] = 0x20
      ..[2] = 0x30
      ..[3] = 0x40;
    target.writeIndex = 1;

    final source = buildMapper45();
    source.outerRegisters
      ..[0] = 0x50
      ..[1] = 0x60
      ..[2] = 0x70
      ..[3] = 0x00;
    source.writeIndex = 3;

    target.state = source.state;

    expect(target.outerRegisters, const [0x50, 0x60, 0x70, 0x00]);
    expect(target.writeIndex, 3);
  });

  test('MMC3 states still deserialize as MMC3State', () {
    const state = MMC3State(
      register: 1,
      r0: 2,
      r1: 3,
      r2: 4,
      r3: 5,
      r4: 6,
      r5: 7,
      r6: 8,
      r7: 9,
      prgBankMode: 1,
      chrBankMode: 0,
      mirroring: 1,
      irqCounter: 10,
      irqLatch: 11,
      irqReload: true,
      irqEnabled: false,
      a12LowStart: 12,
    );

    final writer = Payload.write();

    state.serialize(writer);

    final restored = MapperState.deserialize(Payload.read(binarize(writer)));

    expect(restored, isA<MMC3State>());
    expect(restored, isNot(isA<Mapper45State>()));
  });
}
