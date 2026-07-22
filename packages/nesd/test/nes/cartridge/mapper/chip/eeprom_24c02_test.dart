import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/chip/eeprom_24c02.dart';
import 'package:nesd/nes/cartridge/mapper/chip/eeprom_24c02_state.dart';

/// Drives the EEPROM's I2C inputs like the CPU would through the mapper's
/// serial port register.
class _I2CMaster {
  _I2CMaster(this.eeprom);

  final Eeprom24C02 eeprom;

  void start() {
    eeprom
      ..input(0, 1)
      ..input(1, 1)
      ..input(1, 0)
      ..input(0, 0);
  }

  void stop() {
    eeprom
      ..input(0, 0)
      ..input(1, 0)
      ..input(1, 1);
  }

  /// Clocks out [value] MSB-first and runs the ACK clock cycle.
  ///
  /// Returns `true` if the EEPROM pulled SDA low to acknowledge.
  bool writeByte(int value) {
    for (var i = 7; i >= 0; i--) {
      final bit = (value >> i) & 1;

      eeprom
        ..input(0, bit)
        ..input(1, bit)
        ..input(0, bit);
    }

    // release SDA and clock the ACK bit
    eeprom
      ..input(0, 1)
      ..input(1, 1);

    final acked = eeprom.output == 0;

    eeprom.input(0, 1);

    return acked;
  }

  /// Clocks in a byte MSB-first, then sends an ACK ([ack] is `true`) or a
  /// NAK.
  int readByte({required bool ack}) {
    var value = 0;

    for (var i = 7; i >= 0; i--) {
      eeprom
        ..input(0, 1)
        ..input(1, 1);

      value |= eeprom.output << i;

      eeprom.input(0, 1);
    }

    final sda = ack ? 0 : 1;

    eeprom
      ..input(0, sda)
      ..input(1, sda)
      ..input(0, sda);

    return value;
  }

  /// Starts a write transaction at [address] and sends [values], without
  /// generating a stop condition.
  void writeAt(int address, List<int> values) {
    start();

    expect(writeByte(0xa0), isTrue);
    expect(writeByte(address), isTrue);

    for (final value in values) {
      expect(writeByte(value), isTrue);
    }
  }

  /// Performs a full random read of [count] bytes starting at [address].
  List<int> readAt(int address, int count) {
    start();

    expect(writeByte(0xa0), isTrue);
    expect(writeByte(address), isTrue);

    start();

    expect(writeByte(0xa1), isTrue);

    final values = [
      for (var i = 0; i < count; i++) readByte(ack: i < count - 1),
    ];

    stop();

    return values;
  }
}

Eeprom24C02State _roundTrip(Eeprom24C02State state) {
  final writer = Payload.write();

  state.serialize(writer);

  return Eeprom24C02State.deserialize(Payload.read(binarize(writer)));
}

void main() {
  late Eeprom24C02 eeprom;
  late _I2CMaster master;

  setUp(() {
    eeprom = Eeprom24C02();
    master = _I2CMaster(eeprom);
  });

  test('byte write is only committed after the stop condition', () {
    master.writeAt(0x10, [0x42]);

    expect(eeprom.data[0x10], 0);

    master.stop();

    expect(eeprom.data[0x10], 0x42);
  });

  test('page write commits all buffered bytes on stop', () {
    master.writeAt(0x20, [0x11, 0x22, 0x33, 0x44]);

    expect(eeprom.data.sublist(0x20, 0x24), everyElement(0));

    master.stop();

    expect(eeprom.data.sublist(0x20, 0x24), [0x11, 0x22, 0x33, 0x44]);
  });

  test('page write preserves bytes of the page that were not written', () {
    eeprom.data[0x24] = 0x99;

    master
      ..writeAt(0x20, [0x11, 0x22, 0x33, 0x44])
      ..stop();

    expect(eeprom.data[0x24], 0x99);
  });

  test('page write wraps within the page after 16 bytes', () {
    master
      ..writeAt(0x30, [for (var i = 1; i <= 17; i++) i])
      ..stop();

    expect(eeprom.data[0x30], 17);
    expect(eeprom.data.sublist(0x31, 0x40), [for (var i = 2; i <= 16; i++) i]);
    expect(eeprom.data[0x40], 0);
  });

  test('a start condition aborts a pending write', () {
    master.writeAt(0x50, [0xaa]);

    // repeated start instead of stop: the buffered write must be discarded,
    // also by the stop condition ending the subsequent read
    final values = master.readAt(0x00, 1);

    expect(values, [0]);
    expect(eeprom.data[0x50], 0);
  });

  test('sequential read crosses the page boundary', () {
    eeprom.data.setAll(0x0e, [0xd0, 0xd1, 0xd2, 0xd3]);

    expect(master.readAt(0x0e, 4), [0xd0, 0xd1, 0xd2, 0xd3]);
  });

  test('random read returns the addressed byte', () {
    eeprom.data[0x7f] = 0x5a;

    expect(master.readAt(0x7f, 1), [0x5a]);
  });

  test('control byte for another device is not acknowledged', () {
    master.start();

    expect(master.writeByte(0x50), isFalse);
  });

  group('serialization', () {
    test('state round-trips through serialize and deserialize', () {
      // a page write that has buffered bytes but has not seen a stop
      // condition yet is the most state-heavy moment of the chip
      master.writeAt(0x20, [0x11, 0x22]);

      final state = _roundTrip(eeprom.state);

      expect(state.mode, Eeprom24C02Mode.write);
      expect(state.flush, isTrue);
      expect(state.address, 0x22);
      expect(state.buffer.sublist(0, 2), [0x11, 0x22]);
      expect(state.data, eeprom.data);
      expect(state.output, eeprom.output);
    });

    test('restored chip commits a pending page write on stop', () {
      master.writeAt(0x20, [0x11, 0x22]);

      final restored = Eeprom24C02()..state = _roundTrip(eeprom.state);

      _I2CMaster(restored).stop();

      expect(restored.data.sublist(0x20, 0x22), [0x11, 0x22]);
      expect(eeprom.data[0x20], 0, reason: 'original chip is unaffected');
    });

    test('restored chip serves data written before the snapshot', () {
      master
        ..writeAt(0x40, [0xaa, 0xbb])
        ..stop();

      final restored = Eeprom24C02()..state = _roundTrip(eeprom.state);

      expect(_I2CMaster(restored).readAt(0x40, 2), [0xaa, 0xbb]);
    });
  });
}
