import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/color_dreams_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

void main() {
  group('ColorDreamsState', () {
    test('round-trips through serialization', () {
      const original = ColorDreamsState(prgBank: 3, chrBank: 12);

      final writer = Payload.write();

      original.serialize(writer);

      final bytes = binarize(writer);

      expect(bytes[0], 1, reason: 'MapperState envelope version');
      expect(bytes[1], 0, reason: 'mapper id high byte');
      expect(bytes[2], 11, reason: 'mapper id low byte');
      expect(bytes[3], 0, reason: 'ColorDreamsState version');

      final decoded =
          MapperState.deserialize(Payload.read(bytes)) as ColorDreamsState;

      expect(decoded.id, 11);
      expect(decoded.prgBank, 3);
      expect(decoded.chrBank, 12);
    });

    test('rejects unknown versions', () {
      final writer = Payload.write()
        ..set(uint8, 1) // MapperState envelope version
        ..set(uint16, 11) // mapper id
        ..set(uint8, 1) // ColorDreamsState version
        ..set(uint8, 0)
        ..set(uint8, 0);

      expect(
        () => MapperState.deserialize(Payload.read(binarize(writer))),
        throwsA(isA<InvalidSerializationVersion>()),
      );
    });
  });
}
