import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';
import 'package:nesd/nes/cartridge/mapper/vt/vt02_state.dart';

import 'vt02_harness.dart';

void main() {
  test('round-trips through serialization', () {
    final original = VT02State(
      id: 256,
      bank1: 0x12,
      timerPreload: 0x34,
      decodeControl: 0xc0,
      scrollSelect: 0x01,
      programBanks: Uint8List.fromList([1, 2, 3, 4]),
      bankControl: 0x85,
      ioControl: 0xaa,
      ioData01: 0x5a,
      ioData23: 0xa5,
      rs232TimerLow: 0x67,
      rs232TimerHigh: 0x05,
      rs232Control: 0x20,
      rs232TxData: 0x41,
      dmaControl: 0x3d,
      xop2: 0x0f,
      extendedControl1: 0x81,
      extendedControl2: 0x0c,
      videoBanks: Uint8List.fromList([10, 11, 12, 13, 14, 15]),
      videoBank1: 0x70,
      videoBank0Select: 0xf8,
      timerCounter: 0x7f,
      timerRunning: true,
      timerEnabled: true,
      a12LowStart: 0x123456789a,
      lastScanline: 261,
    );

    final writer = Payload.write();

    original.serialize(writer);

    final bytes = binarize(writer);

    expect(bytes[0], 1, reason: 'MapperState envelope version');
    expect(bytes[1], 1, reason: 'mapper id high byte');
    expect(bytes[2], 0, reason: 'mapper id low byte');
    expect(bytes[3], 0, reason: 'VT02State version');

    final decoded = MapperState.deserialize(Payload.read(bytes)) as VT02State;

    expect(decoded.id, 256);
    expect(decoded.bank1, 0x12);
    expect(decoded.programBanks, original.programBanks);
    expect(decoded.videoBanks, original.videoBanks);
    expect(decoded.bankControl, 0x85);
    expect(decoded.dmaControl, 0x3d);
    expect(decoded.timerCounter, 0x7f);
    expect(decoded.timerRunning, isTrue);
    expect(decoded.timerEnabled, isTrue);
    expect(decoded.a12LowStart, 0x123456789a);
    expect(decoded.lastScanline, 261);
  });

  test('round-trips the register file through the mapper state', () {
    final (nes: sourceNes, mapper: source) = buildVt02();

    const systemAddresses = [
      0x4100,
      0x4101,
      0x4102,
      0x4103,
      0x4104,
      0x4105,
      0x4106,
      0x4107,
      0x4108,
      0x4109,
      0x410a,
      0x410b,
      0x410d,
      0x410e,
      0x410f,
      0x4114,
      0x4115,
      0x4119,
      0x411a,
      0x411b,
    ];

    const graphicsAddresses = [
      0x2010,
      0x2011,
      0x2012,
      0x2013,
      0x2014,
      0x2015,
      0x2016,
      0x2017,
      0x2018,
      0x201a,
    ];

    const unserialized = {0x4102, 0x4103, 0x4104, 0x411b};

    for (var i = 0; i < systemAddresses.length; i++) {
      sourceNes.bus.cpuWrite(systemAddresses[i], i + 1);
    }

    for (var i = 0; i < graphicsAddresses.length; i++) {
      sourceNes.bus.cpuWrite(graphicsAddresses[i], 0x40 + i);
    }

    final target = buildVt02().mapper..state = source.state;

    for (final address in [...systemAddresses, ...graphicsAddresses]) {
      if (unserialized.contains(address)) {
        continue;
      }

      expect(
        target.registerAt(address),
        source.registerAt(address),
        reason: '0x${address.toRadixString(16)}',
      );
    }
  });
}
