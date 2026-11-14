import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper87_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

void main() {
  group('Mapper87State', () {
    test('round-trips through serialization', () {
      const original = Mapper87State(chrBank: 3);

      final writer = Payload.write();

      original.serialize(writer);

      final bytes = binarize(writer);

      expect(bytes[0], 1, reason: 'MapperState envelope version');
      expect(bytes[1], 0, reason: 'mapper id high byte');
      expect(bytes[2], 87, reason: 'mapper id low byte');
      expect(bytes[3], 0, reason: 'Mapper87State version');

      final decoded =
          MapperState.deserialize(Payload.read(bytes)) as Mapper87State;

      expect(decoded.id, 87);
      expect(decoded.chrBank, 3);
    });

    test('rejects unknown versions', () {
      final writer = Payload.write()
        ..set(uint8, 1) // MapperState envelope version
        ..set(uint16, 87) // mapper id
        ..set(uint8, 1) // Mapper87State version
        ..set(uint8, 0);

      expect(
        () => MapperState.deserialize(Payload.read(binarize(writer))),
        throwsA(isA<InvalidSerializationVersion>()),
      );
    });
  });
}
