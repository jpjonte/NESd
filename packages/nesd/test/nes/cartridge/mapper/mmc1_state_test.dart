import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';
import 'package:nesd/nes/cartridge/mapper/mmc1_state.dart';

void main() {
  test('round-trips through serialization', () {
    const original = MMC1State(
      shift: 0x15,
      control: 0x1f,
      chrBank0: 4,
      chrBank1: 9,
      prgBank: 7,
      lastWrite: 0x123456789a,
    );

    final writer = Payload.write();

    original.serialize(writer);

    final bytes = binarize(writer);

    expect(bytes[0], 0, reason: 'MapperState envelope version');
    expect(bytes[1], 1, reason: 'mapper id');
    expect(bytes[2], 1, reason: 'MMC1State version');

    final decoded = MapperState.deserialize(Payload.read(bytes)) as MMC1State;

    expect(decoded.shift, original.shift);
    expect(decoded.control, original.control);
    expect(decoded.chrBank0, original.chrBank0);
    expect(decoded.chrBank1, original.chrBank1);
    expect(decoded.prgBank, original.prgBank);
    expect(decoded.lastWrite, original.lastWrite);
  });

  test('deserializes version 0 payloads with a zero write stamp', () {
    final writer = Payload.write()
      ..set(uint8, 0) // MapperState envelope version
      ..set(uint8, 1) // mapper id
      ..set(uint8, 0) // MMC1State version
      ..set(uint8, 0x15) // shift
      ..set(uint8, 0x1f) // control
      ..set(uint8, 4) // chrBank0
      ..set(uint8, 9) // chrBank1
      ..set(uint8, 7); // prgBank

    final decoded =
        MapperState.deserialize(Payload.read(binarize(writer))) as MMC1State;

    expect(decoded.shift, 0x15);
    expect(decoded.control, 0x1f);
    expect(decoded.chrBank0, 4);
    expect(decoded.chrBank1, 9);
    expect(decoded.prgBank, 7);
    expect(decoded.lastWrite, 0);
  });
}
