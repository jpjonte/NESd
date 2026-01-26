import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cheat/cheat.dart';
import 'package:nesd/nes/cheat/cheat_engine.dart';

void main() {
  group('CheatEngine', () {
    late CheatEngine engine;

    setUp(() {
      engine = CheatEngine();
    });

    group('cheat management', () {
      test('starts with no cheats', () {
        expect(engine.cheats, isEmpty);
      });

      test('addCheat adds a cheat', () {
        final cheat = Cheat(
          id: '1',
          name: 'Test',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0x56,
          code: 'TEST',
        );

        engine.addCheat(cheat);

        expect(engine.cheats, hasLength(1));
        expect(engine.cheats.first, equals(cheat));
      });

      test('addCheat allows multiple cheats', () {
        final cheat1 = Cheat(
          id: '1',
          name: 'Test 1',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0x56,
          code: 'TEST',
        );
        final cheat2 = Cheat(
          id: '2',
          name: 'Test 2',
          type: CheatType.gameGenie,
          address: 0x5678,
          value: 0x9A,
          code: 'TEST',
        );

        engine
          ..addCheat(cheat1)
          ..addCheat(cheat2);

        expect(engine.cheats, hasLength(2));
      });

      test('removeCheat removes cheat by id', () {
        final cheat1 = Cheat(
          id: '1',
          name: 'Test 1',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0x56,
          code: 'TEST',
        );
        final cheat2 = Cheat(
          id: '2',
          name: 'Test 2',
          type: CheatType.gameGenie,
          address: 0x5678,
          value: 0x9A,
          code: 'TEST',
        );

        engine
          ..addCheat(cheat1)
          ..addCheat(cheat2)
          ..removeCheat('1');

        expect(engine.cheats, hasLength(1));
        expect(engine.cheats.first.id, equals('2'));
      });

      test('removeAllCheats clears all cheats', () {
        engine
          ..addCheat(
            Cheat(
              id: '1',
              name: 'Test 1',
              type: CheatType.gameGenie,
              address: 0x1234,
              value: 0x56,
              code: 'TEST',
            ),
          )
          ..addCheat(
            Cheat(
              id: '2',
              name: 'Test 2',
              type: CheatType.gameGenie,
              address: 0x5678,
              value: 0x9A,
              code: 'TEST',
            ),
          )
          ..removeAllCheats();

        expect(engine.cheats, isEmpty);
      });

      test('updateCheat updates existing cheat', () {
        final original = Cheat(
          id: '1',
          name: 'Original',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0x56,
          code: 'TEST',
        );
        engine.addCheat(original);

        final updated = original.copyWith(name: 'Updated', value: 0x78);
        engine.updateCheat(updated);

        expect(engine.cheats, hasLength(1));
        expect(engine.cheats.first.name, equals('Updated'));
        expect(engine.cheats.first.value, equals(0x78));
      });

      test('enableCheat toggles cheat enabled state', () {
        final cheat = Cheat(
          id: '1',
          name: 'Test',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0x56,
          code: 'TEST',
        );

        engine
          ..addCheat(cheat)
          ..enableCheat('1', enabled: false);

        expect(engine.cheats.first.enabled, isFalse);

        engine.enableCheat('1', enabled: true);

        expect(engine.cheats.first.enabled, isTrue);
      });

      test('enableCheat throws when cheat not found', () {
        expect(
          () => engine.enableCheat('nonexistent', enabled: false),
          returnsNormally,
        );
      });
    });

    group('apply', () {
      test('applies cheat without compare value on read', () {
        final cheat = Cheat(
          id: '1',
          name: 'Test',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0xAB,
          code: 'TEST',
        );
        engine.addCheat(cheat);

        final result = engine.apply(0x1234, 0x56);

        expect(result, equals(0xAB));
      });

      test('does not apply cheat to different address', () {
        final cheat = Cheat(
          id: '1',
          name: 'Test',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0xAB,
          code: 'TEST',
        );
        engine.addCheat(cheat);

        final result = engine.apply(0x5678, 0x56);

        expect(result, equals(0x56));
      });

      test('applies cheat with compare value only when value matches', () {
        final cheat = Cheat(
          id: '1',
          name: 'Test',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0xAB,
          code: 'TEST',
          compareValue: 0x56,
        );
        engine.addCheat(cheat);

        // Matching compare value
        expect(engine.apply(0x1234, 0x56), equals(0xAB));

        // Non-matching compare value
        expect(engine.apply(0x1234, 0x78), equals(0x78));
      });

      test('does not apply disabled cheat', () {
        final cheat = Cheat(
          id: '1',
          name: 'Test',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0xAB,
          code: 'TEST',
          enabled: false,
        );
        engine.addCheat(cheat);

        final result = engine.apply(0x1234, 0x56);

        expect(result, equals(0x56));
      });

      test('applies last added cheat when multiple match same address', () {
        final cheat1 = Cheat(
          id: '1',
          name: 'Test 1',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0xAB,
          code: 'TEST',
        );
        final cheat2 = Cheat(
          id: '2',
          name: 'Test 2',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0xCD,
          code: 'TEST',
        );

        engine
          ..addCheat(cheat1)
          ..addCheat(cheat2);

        final result = engine.apply(0x1234, 0x56);

        expect(result, equals(0xCD));
      });
    });
  });
}
