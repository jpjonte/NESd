import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';
import 'package:nesd/nes/cartridge/mapper/nanjing_fc001_state.dart';

void main() {
  group('NanjingFC001State', () {
    test('round-trips through serialization', () {
      const original = NanjingFC001State(
        prgLow: 0x85,
        feedback: 0x05,
        prgHigh: 0x02,
        mode: 0x04,
        pa09: true,
        pa13: false,
      );

      final writer = Payload.write();

      original.serialize(writer);

      final bytes = binarize(writer);

      expect(bytes[0], 1, reason: 'MapperState envelope version');
      expect(bytes[1], 0, reason: 'mapper id high byte');
      expect(bytes[2], 163, reason: 'mapper id low byte');
      expect(bytes[3], 0, reason: 'NanjingFC001State version');

      final decoded =
          MapperState.deserialize(Payload.read(bytes)) as NanjingFC001State;

      expect(decoded.id, 163);
      expect(decoded.prgLow, 0x85);
      expect(decoded.feedback, 0x05);
      expect(decoded.prgHigh, 0x02);
      expect(decoded.mode, 0x04);
      expect(decoded.pa09, isTrue);
      expect(decoded.pa13, isFalse);
    });

    test('rejects unknown versions', () {
      final writer = Payload.write()
        ..set(uint8, 1) // MapperState envelope version
        ..set(uint16, 163) // mapper id
        ..set(uint8, 1); // NanjingFC001State version

      expect(
        () => MapperState.deserialize(Payload.read(binarize(writer))),
        throwsA(isA<InvalidSerializationVersion>()),
      );
    });
  });
}
