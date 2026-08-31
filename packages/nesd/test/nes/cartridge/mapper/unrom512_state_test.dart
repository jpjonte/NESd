import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';
import 'package:nesd/nes/cartridge/mapper/unrom512_state.dart';

void main() {
  test('round-trips through serialization', () {
    const original = UNROM512State(latch: 0xa5);

    final writer = Payload.write();

    original.serialize(writer);

    final bytes = binarize(writer);

    expect(bytes[0], 0, reason: 'MapperState envelope version');
    expect(bytes[1], 30, reason: 'mapper id');
    expect(bytes[2], 0, reason: 'UNROM512State version');

    final decoded =
        MapperState.deserialize(Payload.read(bytes)) as UNROM512State;

    expect(decoded.latch, 0xa5);
  });
}
