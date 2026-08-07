import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/mapper176_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';
import 'package:nesd/nes/cartridge/mapper/mmc3_state.dart';

import 'mapper176_harness.dart';

void main() {
  Mapper176State roundTrip(Mapper176State state) {
    final writer = Payload.write();

    state.serialize(writer);

    return MapperState.deserialize(Payload.read(binarize(writer)))
        as Mapper176State;
  }

  test('round-trips the MMC3 and outer registers', () {
    final mapper = buildMapper176(subMapper: 1)
      ..cpuWrite(0x5013, 0x02)
      ..cpuWrite(0x5010, 0x35)
      ..cpuWrite(0x5011, 0x2a)
      ..cpuWrite(0x5012, 0xa5)
      ..cpuWrite(0x8000, 9)
      ..cpuWrite(0x8001, 0x77)
      ..cpuWrite(0xc000, 0x42);

    final restored = roundTrip(mapper.state);

    expect(restored.id, 176);
    expect(restored.mode, 0x35);
    expect(restored.prgBaseLsb, 0x2a);
    expect(restored.chrBaseLsb, 0xa5);
    expect(restored.extendedRegister, 0x02);
    expect(restored.bank9, 0x77);
    expect(restored.irqLatch, 0x42);
  });

  test('restoring re-maps the windows', () {
    final source = buildMapper176()
      ..cpuWrite(0x5010, 4) // NROM-256
      ..cpuWrite(0x5011, 0x06);

    final target = buildMapper176()..state = source.state;

    expect(target.cpuRead(0x8000), 0x0c);
    expect(target.cpuRead(0xe000), 0x0f);
  });

  test('restoring overwrites live fields that differ from the saved '
      'state', () {
    final target = buildMapper176(subMapper: 1)
      ..mode = 0x11
      ..prgBaseLsb = 0x22
      ..prgBaseMsb = 0x03
      ..chrBaseLsb = 0x44
      ..chrBaseMsb = 0x05
      ..extendedRegister = 0x06
      ..unromLatch = 0x07
      ..cnromLatch = 0x08;

    target.banks
      ..[8] = 0x10
      ..[9] = 0x20
      ..[10] = 0x30
      ..[11] = 0x40;

    final source = buildMapper176(subMapper: 1)
      ..mode = 0x51
      ..prgBaseLsb = 0x62
      ..prgBaseMsb = 0x13
      ..chrBaseLsb = 0x74
      ..chrBaseMsb = 0x15
      ..extendedRegister = 0x16
      ..unromLatch = 0x17
      ..cnromLatch = 0x18;

    source.banks
      ..[8] = 0x90
      ..[9] = 0xa0
      ..[10] = 0xb0
      ..[11] = 0xc0;

    target.state = source.state;

    expect(target.mode, 0x51);
    expect(target.prgBaseLsb, 0x62);
    expect(target.prgBaseMsb, 0x13);
    expect(target.chrBaseLsb, 0x74);
    expect(target.chrBaseMsb, 0x15);
    expect(target.extendedRegister, 0x16);
    expect(target.unromLatch, 0x17);
    expect(target.cnromLatch, 0x18);
    expect(target.banks[8], 0x90);
    expect(target.banks[9], 0xa0);
    expect(target.banks[10], 0xb0);
    expect(target.banks[11], 0xc0);
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
    expect(restored, isNot(isA<Mapper176State>()));
    expect((restored as MMC3State).r7, 9);
  });
}
