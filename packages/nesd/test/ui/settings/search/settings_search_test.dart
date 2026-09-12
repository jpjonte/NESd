import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';
import 'package:nesd/ui/settings/search/settings_search.dart';

void main() {
  List<String> titles(String query) => [
    for (final match in searchSettings(query)) match.entry.title,
  ];

  test('a blank query matches nothing', () {
    expect(searchSettings(''), isEmpty);
    expect(searchSettings('   '), isEmpty);
  });

  test('"player 2 start" ranks Controller 2 Start first', () {
    final matches = searchSettings('player 2 start');

    expect(matches, isNotEmpty);
    expect(matches.first.entry.title, 'Controller 2 Start');
    expect(matches.first.group?.title, 'Player 2');
    expect(titles('player 2 start'), isNot(contains('Controller 1 Start')));
  });

  test('"save state 3" ranks Save State 3 above Load State 3', () {
    final result = titles('save state 3');

    expect(result.first, 'Save State 3');
    expect(result, contains('Load State 3'));
  });

  test('a word that only appears in a subtitle matches', () {
    expect(titles('timer').first, 'Auto Save');
  });

  test('matching is case-insensitive', () {
    expect(titles('LOW PASS'), titles('low pass'));
    expect(titles('low pass').first, 'Low Pass Filter');
  });

  test('registry order breaks score ties', () {
    final ids = [for (final m in searchSettings('controller 1')) m.id];

    final up = ids.indexOf('controls.bindings.player1/Controller 1 Up');
    final down = ids.indexOf('controls.bindings.player1/Controller 1 Down');

    expect(up, isNonNegative);
    expect(down, isNonNegative);
    expect(up, lessThan(down));
  });

  test('every match is a registry location', () {
    for (final match in searchSettings('a')) {
      expect(settingsEntryLocations, contains(match));
    }
  });
}
