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
        );
        final cheat2 = Cheat(
          id: '2',
          name: 'Test 2',
          type: CheatType.gameGenie,
          address: 0x5678,
          value: 0x9A,
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
        );
        final cheat2 = Cheat(
          id: '2',
          name: 'Test 2',
          type: CheatType.gameGenie,
          address: 0x5678,
          value: 0x9A,
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
            ),
          )
          ..addCheat(
            Cheat(
              id: '2',
              name: 'Test 2',
              type: CheatType.gameGenie,
              address: 0x5678,
              value: 0x9A,
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
          throwsException,
        );
      });
    });

    group('applyOnRead', () {
      test('applies cheat without compare value on read', () {
        final cheat = Cheat(
          id: '1',
          name: 'Test',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0xAB,
        );
        engine.addCheat(cheat);

        final result = engine.applyOnRead(0x1234, 0x56);

        expect(result, equals(0xAB));
      });

      test('does not apply cheat to different address', () {
        final cheat = Cheat(
          id: '1',
          name: 'Test',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0xAB,
        );
        engine.addCheat(cheat);

        final result = engine.applyOnRead(0x5678, 0x56);

        expect(result, equals(0x56));
      });

      test('applies cheat with compare value only when value matches', () {
        final cheat = Cheat(
          id: '1',
          name: 'Test',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0xAB,
          compareValue: 0x56,
        );
        engine.addCheat(cheat);

        // Matching compare value
        expect(engine.applyOnRead(0x1234, 0x56), equals(0xAB));

        // Non-matching compare value
        expect(engine.applyOnRead(0x1234, 0x78), equals(0x78));
      });

      test('does not apply disabled cheat', () {
        final cheat = Cheat(
          id: '1',
          name: 'Test',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0xAB,
          enabled: false,
        );
        engine.addCheat(cheat);

        final result = engine.applyOnRead(0x1234, 0x56);

        expect(result, equals(0x56));
      });

      test('applies first matching cheat when multiple match', () {
        final cheat1 = Cheat(
          id: '1',
          name: 'Test 1',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0xAB,
        );
        final cheat2 = Cheat(
          id: '2',
          name: 'Test 2',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0xCD,
        );

        engine
          ..addCheat(cheat1)
          ..addCheat(cheat2);

        final result = engine.applyOnRead(0x1234, 0x56);

        expect(result, equals(0xAB));
      });
    });

    group('applyOnWrite', () {
      test('applies cheat without compare value on write', () {
        final cheat = Cheat(
          id: '1',
          name: 'Test',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0xAB,
        );
        engine.addCheat(cheat);

        final result = engine.applyOnWrite(0x1234, 0x56);

        expect(result, equals(0xAB));
      });

      test('does not apply cheat to different address', () {
        final cheat = Cheat(
          id: '1',
          name: 'Test',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0xAB,
        );
        engine.addCheat(cheat);

        final result = engine.applyOnWrite(0x5678, 0x56);

        expect(result, equals(0x56));
      });

      test('applies cheat with compare value only when value matches', () {
        final cheat = Cheat(
          id: '1',
          name: 'Test',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0xAB,
          compareValue: 0x56,
        );
        engine.addCheat(cheat);

        // Matching compare value
        expect(engine.applyOnWrite(0x1234, 0x56), equals(0xAB));

        // Non-matching compare value
        expect(engine.applyOnWrite(0x1234, 0x78), equals(0x78));
      });

      test('does not apply disabled cheat', () {
        final cheat = Cheat(
          id: '1',
          name: 'Test',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0xAB,
          enabled: false,
        );
        engine.addCheat(cheat);

        final result = engine.applyOnWrite(0x1234, 0x56);

        expect(result, equals(0x56));
      });
    });

    group('applyFrameCheats', () {
      test('writes all enabled cheats to memory', () {
        final writes = <int, int>{};
        void writeMemory(int address, int value) {
          writes[address] = value;
        }

        final cheat1 = Cheat(
          id: '1',
          name: 'Test 1',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0xAB,
        );
        final cheat2 = Cheat(
          id: '2',
          name: 'Test 2',
          type: CheatType.gameGenie,
          address: 0x5678,
          value: 0xCD,
        );

        engine
          ..addCheat(cheat1)
          ..addCheat(cheat2)
          ..applyFrameCheats(writeMemory);

        expect(writes[0x1234], equals(0xAB));
        expect(writes[0x5678], equals(0xCD));
      });

      test('does not write disabled cheats', () {
        final writes = <int, int>{};
        void writeMemory(int address, int value) {
          writes[address] = value;
        }

        final cheat = Cheat(
          id: '1',
          name: 'Test',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0xAB,
          enabled: false,
        );

        engine
          ..addCheat(cheat)
          ..applyFrameCheats(writeMemory);

        expect(writes, isEmpty);
      });
    });

    group('serialization', () {
      test('toJson serializes engine state', () {
        final cheat1 = Cheat(
          id: '1',
          name: 'Test 1',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0x56,
        );
        final cheat2 = Cheat(
          id: '2',
          name: 'Test 2',
          type: CheatType.gameGenie,
          address: 0x5678,
          value: 0x9A,
        );

        engine
          ..addCheat(cheat1)
          ..addCheat(cheat2);

        final json = engine.toJson();

        expect(json['cheats'], hasLength(2));
      });

      test('fromJson restores engine state', () {
        final json = {
          'cheats': [
            {
              'id': '1',
              'name': 'Test 1',
              'type': 'gameGenie',
              'address': 0x1234,
              'value': 0x56,
              'enabled': true,
            },
            {
              'id': '2',
              'name': 'Test 2',
              'type': 'gameGenie',
              'address': 0x5678,
              'value': 0x9A,
              'enabled': false,
            },
          ],
        };

        engine.fromJson(json);

        expect(engine.cheats, hasLength(2));
        expect(engine.cheats[0].name, equals('Test 1'));
        expect(engine.cheats[0].enabled, isTrue);
        expect(engine.cheats[1].name, equals('Test 2'));
        expect(engine.cheats[1].enabled, isFalse);
      });

      test('fromJson clears existing cheats', () {
        engine.addCheat(
          Cheat(
            id: '1',
            name: 'Existing',
            type: CheatType.gameGenie,
            address: 0x1234,
            value: 0x56,
          ),
        );

        final json = {'cheats': <Map<String, dynamic>>[]};

        engine.fromJson(json);

        expect(engine.cheats, isEmpty);
      });

      test('fromJson handles null cheats list', () {
        final json = <String, dynamic>{};

        engine.fromJson(json);

        expect(engine.cheats, isEmpty);
      });
    });

    group('reset', () {
      test('reset does not remove cheats', () {
        final cheat = Cheat(
          id: '1',
          name: 'Test',
          type: CheatType.gameGenie,
          address: 0x1234,
          value: 0x56,
        );

        engine
          ..addCheat(cheat)
          ..reset();

        expect(engine.cheats, hasLength(1));
      });
    });
  });
}
