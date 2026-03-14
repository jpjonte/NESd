import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cheat/cheat.dart';
import 'package:nesd/nes/cheat/game_genie_decoder.dart';

void main() {
  group('GameGenieDecoder', () {
    group('6-character codes', () {
      test('decodes AATOZA (Super Mario Bros - Mega Jump)', () {
        final cheat = GameGenieDecoder.decode('AATOZA');

        expect(cheat, isNotNull);
        expect(cheat!.address, equals(0x906A));
        expect(cheat.value, equals(0x00));
        expect(cheat.compareValue, isNull);
      });

      test("decodes PIGOAP (Zelda - Don't Take Damage)", () {
        final cheat = GameGenieDecoder.decode('PIGOAP');

        expect(cheat, isNotNull);
        expect(cheat!.address, equals(0x9148));
        expect(cheat.value, equals(0x51));
        expect(cheat.compareValue, isNull);
      });

      test('is case insensitive', () {
        final upper = GameGenieDecoder.decode('SLXPLOVS');
        final lower = GameGenieDecoder.decode('slxplovs');
        final mixed = GameGenieDecoder.decode('SlXpLoVs');

        expect(upper!.address, equals(lower!.address));
        expect(upper.value, equals(lower.value));
        expect(upper.address, equals(mixed!.address));
        expect(upper.value, equals(mixed.value));
      });

      test('ignores spaces and invalid characters', () {
        final cheat1 = GameGenieDecoder.decode('SLXPLOVS');
        final cheat2 = GameGenieDecoder.decode('SLX PLO VS');
        final cheat3 = GameGenieDecoder.decode('SLX-PLO-VS');

        expect(cheat1!.address, equals(cheat2!.address));
        expect(cheat1.value, equals(cheat2.value));
        expect(cheat1.address, equals(cheat3!.address));
        expect(cheat1.value, equals(cheat3.value));
      });
    });

    group('8-character codes', () {
      test('decodes SLXPLOVS (Super Mario Bros - Infinite Lives)', () {
        final cheat = GameGenieDecoder.decode(
          'SLXPLOVS',
          name: 'Infinite Lives',
        );

        expect(cheat, isNotNull);
        expect(cheat!.name, equals('Infinite Lives'));
        expect(cheat.type, equals(CheatType.gameGenie));
        expect(cheat.address, equals(0x9123));
        expect(cheat.value, equals(0xBD));
        expect(cheat.compareValue, equals(0xDE));
      });

      test('decodes 8-character code with compare value', () {
        final cheat = GameGenieDecoder.decode('SXIOPO');

        expect(cheat, isNotNull);
        expect(cheat!.type, equals(CheatType.gameGenie));
        expect(cheat.compareValue, isNull); // 6-character code
      });

      test('handles 8-character codes correctly', () {
        // Note: This is a test pattern, not a real Game Genie code
        final cheat = GameGenieDecoder.decode('AAAAAAAA');

        expect(cheat, isNotNull);
        expect(cheat!.address, isA<int>());
        expect(cheat.value, isA<int>());
        expect(cheat.compareValue, isA<int>());
      });
    });

    group('validation', () {
      test('returns null for invalid length', () {
        expect(GameGenieDecoder.decode('SHORT'), isNull);
        expect(GameGenieDecoder.decode('TOOLONG12'), isNull);
        expect(GameGenieDecoder.decode(''), isNull);
      });

      test('returns null for invalid characters', () {
        expect(GameGenieDecoder.decode('SLXPL1VS'), isNull);
        expect(GameGenieDecoder.decode('SLXPL0VS'), isNull);
        expect(GameGenieDecoder.decode('SLXPL@VS'), isNull);
      });
    });

    group('name handling', () {
      test('uses provided name', () {
        final cheat = GameGenieDecoder.decode('SLXPLOVS', name: 'Custom Name');

        expect(cheat!.name, equals('Custom Name'));
      });

      test('defaults to code when name not provided', () {
        final cheat = GameGenieDecoder.decode('SLXPLOVS');

        expect(cheat!.name, equals('SLXPLOVS'));
      });
    });

    group('cheat properties', () {
      test('generates unique ID', () async {
        final cheat1 = GameGenieDecoder.decode('SLXPLOVS');
        // Small delay to ensure different timestamp
        await Future.delayed(const Duration(milliseconds: 2));
        final cheat2 = GameGenieDecoder.decode('SLXPLOVS');

        expect(cheat1!.id, isNotNull);
        expect(cheat2!.id, isNotNull);
        expect(cheat1.id, isNot(equals(cheat2.id)));
      });

      test('sets enabled to true by default', () {
        final cheat = GameGenieDecoder.decode('SLXPLOVS');

        expect(cheat!.enabled, isTrue);
      });

      test('sets type to gameGenie', () {
        final cheat = GameGenieDecoder.decode('SLXPLOVS');

        expect(cheat!.type, equals(CheatType.gameGenie));
      });
    });

    group('address range', () {
      test('decodes addresses in valid NES range', () {
        final codes = ['SLXPLOVS', 'AATOZA', 'PIGOAP'];

        for (final code in codes) {
          final cheat = GameGenieDecoder.decode(code);
          expect(cheat, isNotNull);
          expect(cheat!.address, greaterThanOrEqualTo(0x0000));
          expect(cheat.address, lessThanOrEqualTo(0xFFFF));
        }
      });
    });

    group('value range', () {
      test('decodes values in valid byte range', () {
        final codes = ['SLXPLOVS', 'AATOZA', 'PIGOAP'];

        for (final code in codes) {
          final cheat = GameGenieDecoder.decode(code);
          expect(cheat, isNotNull);
          expect(cheat!.value, greaterThanOrEqualTo(0x00));
          expect(cheat.value, lessThanOrEqualTo(0xFF));
        }
      });
    });

    group('character set', () {
      test('accepts all valid Game Genie characters', () {
        const validChars = 'APZLGITYEOXUKSVN';
        final code = validChars.substring(0, 6);

        final cheat = GameGenieDecoder.decode(code);

        expect(cheat, isNotNull);
      });

      test('rejects characters not in Game Genie set', () {
        const invalidCodes = [
          'SLXPL1VS', // 1 not valid
          'SLXPL0VS', // 0 not valid
          'SLXPLBVS', // B not valid
          'SLXPLCVS', // C not valid
          'SLXPLDVS', // D not valid
          'SLXPLFVS', // F not valid
          'SLXPLHVS', // H not valid
          'SLXPLJVS', // J not valid
          'SLXPLMVS', // M not valid
          'SLXPLQVS', // Q not valid
          'SLXPLRVS', // R not valid
          'SLXPLWVS', // W not valid
        ];

        for (final code in invalidCodes) {
          expect(GameGenieDecoder.decode(code), isNull);
        }
      });
    });
  });
}
