import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/bandai_discrete_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

void main() {
  group('BandaiDiscreteState', () {
    test('round-trips through serialization', () {
      const original = BandaiDiscreteState(
        prgBank: 7,
        chrBank: 12,
        nametable: 1,
        id: 152,
      );

      final writer = Payload.write();

      original.serialize(writer);

      final bytes = binarize(writer);

      expect(bytes[0], 1, reason: 'MapperState envelope version');
      expect(bytes[1], 0, reason: 'mapper id high byte');
      expect(bytes[2], 152, reason: 'mapper id low byte');
      expect(bytes[3], 0, reason: 'BandaiDiscreteState version');

      final decoded =
          MapperState.deserialize(Payload.read(bytes)) as BandaiDiscreteState;

      expect(decoded.id, 152);
      expect(decoded.prgBank, 7);
      expect(decoded.chrBank, 12);
      expect(decoded.nametable, 1);
    });

    test('keeps mapper id 70 through serialization', () {
      const original = BandaiDiscreteState(
        prgBank: 9,
        chrBank: 3,
        nametable: 0,
        id: 70,
      );

      final writer = Payload.write();

      original.serialize(writer);

      final decoded =
          MapperState.deserialize(Payload.read(binarize(writer)))
              as BandaiDiscreteState;

      expect(decoded.id, 70);
      expect(decoded.prgBank, 9);
      expect(decoded.chrBank, 3);
    });

    test('rejects unknown versions', () {
      final writer = Payload.write()
        ..set(uint8, 1) // MapperState envelope version
        ..set(uint16, 70) // mapper id
        ..set(uint8, 1) // BandaiDiscreteState version
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
