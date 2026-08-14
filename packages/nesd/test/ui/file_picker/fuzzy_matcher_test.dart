import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/file_picker/fuzzy_matcher.dart';

void main() {
  group('fuzzyScore', () {
    group('matching', () {
      test('matches when query words appear as words in the target', () {
        expect(fuzzyScore('Super Bros', 'Super Mario Bros.nes'), isNotNull);
      });

      test('matches when query is a subsequence of the target', () {
        expect(fuzzyScore('supebro', 'Super Mario Bros.nes'), isNotNull);
      });

      test('matches case-insensitively', () {
        expect(fuzzyScore('SUPER', 'super mario bros.nes'), isNotNull);
      });

      test('matches query words in any order', () {
        expect(fuzzyScore('bros super', 'Super Mario Bros.nes'), isNotNull);
      });

      test('matches everything when the query is blank', () {
        expect(fuzzyScore('', 'Super Mario Bros.nes'), isNotNull);
        expect(fuzzyScore('   ', 'Super Mario Bros.nes'), isNotNull);
      });
    });

    group('non-matching', () {
      test('does not match when query characters are missing', () {
        expect(fuzzyScore('metroid', 'Super Mario Bros.nes'), isNull);
      });

      test('does not match when characters appear out of order', () {
        expect(fuzzyScore('orb', 'Bros.nes'), isNull);
      });

      test('does not match when only some query words match', () {
        expect(fuzzyScore('super metroid', 'Super Mario Bros.nes'), isNull);
      });
    });

    group('ranking', () {
      test('ranks contiguous matches above scattered matches', () {
        final contiguous = fuzzyScore('mario', 'Super Mario Bros.nes');
        final scattered = fuzzyScore('mario', 'Mah Jong Trio.nes');

        expect(contiguous, isNotNull);
        expect(scattered, isNotNull);
        expect(contiguous, greaterThan(scattered!));
      });

      test('ranks word-boundary matches above mid-word matches', () {
        final boundary = fuzzyScore('zelda', 'Zelda.nes');
        final midWord = fuzzyScore('zelda', 'Bazelda.nes');

        expect(boundary, isNotNull);
        expect(midWord, isNotNull);
        expect(boundary, greaterThan(midWord!));
      });

      test(
        'prefers a later contiguous match over an earlier scattered one',
        () {
          final wordStart = fuzzyScore('bro', 'Bomberman Bros.nes');
          final scattered = fuzzyScore('bro', 'Bomberman Rooms.nes');

          expect(wordStart, isNotNull);
          expect(scattered, isNotNull);
          expect(wordStart, greaterThan(scattered!));
        },
      );
    });
  });
}
