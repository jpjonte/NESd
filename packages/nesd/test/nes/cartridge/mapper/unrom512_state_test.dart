import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';
import 'package:nesd/nes/cartridge/mapper/unrom512_state.dart';

void main() {
  test('round-trips through serialization', () {
    final original = UNROM512State(
      latch: 0xa5,
      flashSectors: {
        2: Uint8List.fromList(List.filled(0x1000, 0x11)),
        7: Uint8List.fromList(List.filled(0x1000, 0x22)),
      },
    );

    final writer = Payload.write();

    original.serialize(writer);

    final bytes = binarize(writer);

    expect(bytes[0], 0, reason: 'MapperState envelope version');
    expect(bytes[1], 30, reason: 'mapper id');
    expect(bytes[2], 0, reason: 'UNROM512State version');

    final decoded =
        MapperState.deserialize(Payload.read(bytes)) as UNROM512State;

    expect(decoded.latch, 0xa5);
    expect(decoded.flashSectors.keys, unorderedEquals([2, 7]));
    expect(decoded.flashSectors[2], everyElement(0x11));
    expect(decoded.flashSectors[7], everyElement(0x22));
    expect(decoded.flashSectors[2], hasLength(0x1000));
  });

  test('round-trips with no flashed sectors', () {
    const original = UNROM512State(latch: 0x1f, flashSectors: {});

    final writer = Payload.write();

    original.serialize(writer);

    final decoded =
        MapperState.deserialize(Payload.read(binarize(writer)))
            as UNROM512State;

    expect(decoded.latch, 0x1f);
    expect(decoded.flashSectors, isEmpty);
  });
}
