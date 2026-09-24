import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';
import 'package:nesd/nes/cartridge/mapper/nina003006_state.dart';

void main() {
  group('NINA003006State', () {
    test('round-trips through serialization', () {
      const original = NINA003006State(prgBank: 1, chrBank: 5, id: 79);

      final writer = Payload.write();

      original.serialize(writer);

      final bytes = binarize(writer);

      expect(bytes[0], 1, reason: 'MapperState envelope version');
      expect(bytes[1], 0, reason: 'mapper id high byte');
      expect(bytes[2], 79, reason: 'mapper id low byte');
      expect(bytes[3], 0, reason: 'NINA003006State version');

      final decoded =
          MapperState.deserialize(Payload.read(bytes)) as NINA003006State;

      expect(decoded.id, 79);
      expect(decoded.prgBank, 1);
      expect(decoded.chrBank, 5);
    });

    test('keeps mapper id 146 through serialization', () {
      const original = NINA003006State(prgBank: 1, chrBank: 2, id: 146);

      final writer = Payload.write();

      original.serialize(writer);

      final decoded =
          MapperState.deserialize(Payload.read(binarize(writer)))
              as NINA003006State;

      expect(decoded.id, 146);
      expect(decoded.prgBank, 1);
      expect(decoded.chrBank, 2);
    });

    test('rejects unknown versions', () {
      final writer = Payload.write()
        ..set(uint8, 1) // MapperState envelope version
        ..set(uint16, 79) // mapper id
        ..set(uint8, 1) // NINA003006State version
        ..set(uint8, 0)
        ..set(uint8, 0);

      expect(
        () => MapperState.deserialize(Payload.read(binarize(writer))),
        throwsA(isA<InvalidSerializationVersion>()),
      );
    });
  });
}
