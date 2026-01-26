import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cheat/cheat.dart';

void main() {
  group('Cheat', () {
    test('copyWith creates new instance with updated fields', () {
      final original = Cheat(
        id: '1',
        name: 'Original',
        type: CheatType.gameGenie,
        address: 0x1234,
        value: 0x56,
        code: 'TEST',
      );

      final updated = original.copyWith(name: 'Updated', enabled: false);

      expect(updated.id, equals(original.id));
      expect(updated.name, equals('Updated'));
      expect(updated.type, equals(original.type));
      expect(updated.address, equals(original.address));
      expect(updated.value, equals(original.value));
      expect(updated.code, equals('TEST'));
      expect(updated.enabled, isFalse);
    });

    test('toJson serializes correctly', () {
      final cheat = Cheat(
        id: '123',
        name: 'Test Cheat',
        type: CheatType.gameGenie,
        address: 0x1234,
        value: 0x56,
        code: 'TEST',
        compareValue: 0x78,
        enabled: false,
      );

      final json = cheat.toJson();

      expect(json['id'], equals('123'));
      expect(json['name'], equals('Test Cheat'));
      expect(json['type'], equals('gameGenie'));
      expect(json['address'], equals(0x1234));
      expect(json['value'], equals(0x56));
      expect(json['code'], equals('TEST'));
      expect(json['compareValue'], equals(0x78));
      expect(json['enabled'], isFalse);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'id': '123',
        'name': 'Test Cheat',
        'type': 'gameGenie',
        'address': 0x1234,
        'value': 0x56,
        'code': 'TEST',
        'compareValue': 0x78,
        'enabled': false,
      };

      final cheat = Cheat.fromJson(json);

      expect(cheat.id, equals('123'));
      expect(cheat.name, equals('Test Cheat'));
      expect(cheat.type, equals(CheatType.gameGenie));
      expect(cheat.address, equals(0x1234));
      expect(cheat.value, equals(0x56));
      expect(cheat.code, equals('TEST'));
      expect(cheat.compareValue, equals(0x78));
      expect(cheat.enabled, isFalse);
    });

    test('handles null compareValue in JSON', () {
      final json = {
        'id': '123',
        'name': 'Test Cheat',
        'type': 'gameGenie',
        'address': 0x1234,
        'value': 0x56,
        'code': 'TEST',
        'enabled': true,
      };

      final cheat = Cheat.fromJson(json);

      expect(cheat.compareValue, isNull);
    });

    test('round-trip serialization preserves data', () {
      final original = Cheat(
        id: '123',
        name: 'Test Cheat',
        type: CheatType.gameGenie,
        address: 0x1234,
        value: 0x56,
        code: 'TEST',
        compareValue: 0x78,
        enabled: false,
      );

      final json = original.toJson();
      final restored = Cheat.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.type, equals(original.type));
      expect(restored.address, equals(original.address));
      expect(restored.value, equals(original.value));
      expect(restored.compareValue, equals(original.compareValue));
      expect(restored.enabled, equals(original.enabled));
    });
  });
}
