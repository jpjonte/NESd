import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper34_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

void main() {
  group('Mapper34State', () {
    test('round-trips through serialization', () {
      const original = Mapper34State(
        prgBank: 3,
        chrBank0: 5,
        chrBank1: 9,
        id: 34,
      );

      final writer = Payload.write();

      original.serialize(writer);

      final bytes = binarize(writer);

      expect(bytes[0], 1, reason: 'MapperState envelope version');
      expect(bytes[1], 0, reason: 'mapper id high byte');
      expect(bytes[2], 34, reason: 'mapper id low byte');
      expect(bytes[3], 0, reason: 'Mapper34State version');

      final decoded =
          MapperState.deserialize(Payload.read(bytes)) as Mapper34State;

      expect(decoded.id, 34);
      expect(decoded.prgBank, 3);
      expect(decoded.chrBank0, 5);
      expect(decoded.chrBank1, 9);
    });

    test('keeps mapper id 241 through serialization', () {
      const original = Mapper34State(
        prgBank: 2,
        chrBank0: 0,
        chrBank1: 1,
        id: 241,
      );

      final writer = Payload.write();

      original.serialize(writer);

      final decoded =
          MapperState.deserialize(Payload.read(binarize(writer)))
              as Mapper34State;

      expect(decoded.id, 241);
      expect(decoded.prgBank, 2);
    });

    test('rejects unknown versions', () {
      final writer = Payload.write()
        ..set(uint8, 1) // MapperState envelope version
        ..set(uint16, 34) // mapper id
        ..set(uint8, 1) // Mapper34State version
        ..set(uint8, 0)
        ..set(uint8, 0)
        ..set(uint8, 0);

      expect(
        () => MapperState.deserialize(Payload.read(binarize(writer))),
        throwsA(isA<InvalidSerializationVersion>()),
      );
    });
  });
}
