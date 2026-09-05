import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';
import 'package:nesd/nes/cartridge/mapper/unrom512_state.dart';

void main() {
  group('peekId', () {
    test('reads the mapper id a state just serialized', () {
      const state = UNROM512State(latch: 0, flashSectors: {});

      final writer = Payload.write();

      state.serialize(writer);

      expect(MapperState.peekId(binarize(writer)), 30);
    });

    test('reads a mapper id that does not fit in a byte', () {
      final writer = Payload.write()
        ..set(uint8, 1) // MapperState envelope version
        ..set(uint16, 256); // mapper id

      expect(MapperState.peekId(binarize(writer)), 256);
    });

    test('reads the mapper id from a version 0 envelope', () {
      final writer = Payload.write()
        ..set(uint8, 0) // MapperState envelope version
        ..set(uint8, 30); // mapper id

      expect(MapperState.peekId(binarize(writer)), 30);
    });

    test('returns null for an unknown envelope version', () {
      final writer = Payload.write()
        ..set(uint8, 2) // MapperState envelope version
        ..set(uint16, 30); // mapper id

      expect(MapperState.peekId(binarize(writer)), isNull);
    });

    test('returns null when the id is cut short', () {
      final writer = Payload.write()
        ..set(uint8, 1) // MapperState envelope version
        ..set(uint8, 0); // half a mapper id

      expect(MapperState.peekId(binarize(writer)), isNull);
    });

    test('returns null for an empty payload', () {
      expect(MapperState.peekId(binarize(Payload.write())), isNull);
    });
  });
}
