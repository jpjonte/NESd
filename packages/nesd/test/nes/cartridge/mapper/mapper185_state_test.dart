import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper185_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

void main() {
  group('Mapper185State', () {
    test('round-trips through serialization', () {
      const original = Mapper185State(latch: 0x21, disabledReads: 1);

      final writer = Payload.write();

      original.serialize(writer);

      final bytes = binarize(writer);

      expect(bytes[0], 1, reason: 'MapperState envelope version');
      expect(bytes[1], 0, reason: 'mapper id high byte');
      expect(bytes[2], 185, reason: 'mapper id low byte');
      expect(bytes[3], 0, reason: 'Mapper185State version');

      final decoded =
          MapperState.deserialize(Payload.read(bytes)) as Mapper185State;

      expect(decoded.id, 185);
      expect(decoded.latch, 0x21);
      expect(decoded.disabledReads, 1);
    });

    test('rejects an unknown version', () {
      final writer = Payload.write()
        ..set(uint8, 1)
        ..set(uint16, 185)
        ..set(uint8, 99);

      expect(
        () => MapperState.deserialize(Payload.read(binarize(writer))),
        throwsA(isA<InvalidSerializationVersion>()),
      );
    });
  });
}
