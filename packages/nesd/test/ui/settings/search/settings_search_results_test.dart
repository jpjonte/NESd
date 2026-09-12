import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';
import 'package:nesd/ui/settings/search/settings_search.dart';
import 'package:nesd/ui/settings/search/settings_search_results.dart';
import 'package:nesd/ui/theme/light.dart';

import '../../../helpers/fonts.dart';

void main() {
  Future<List<SettingsEntryLocation>> pumpResults(
    WidgetTester tester,
    List<SettingsEntryLocation> matches,
  ) async {
    final selected = <SettingsEntryLocation>[];

    await loadAppFonts();

    await tester.pumpWidget(
      MaterialApp(
        theme: nesdThemeLight,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SettingsSearchResults(
              matches: matches,
              onSelect: selected.add,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return selected;
  }

  testWidgets('shows one row per match with title and breadcrumb', (
    tester,
  ) async {
    final matches = searchSettings('player 2 start');

    await pumpResults(tester, matches);

    for (final match in matches) {
      expect(
        find.byKey(SettingsSearchResults.rowKey(match.id)),
        findsOneWidget,
      );
    }

    expect(find.text('Controller 2 Start'), findsOneWidget);
    expect(find.text('Controls › Bindings › Player 2'), findsOneWidget);
    expect(find.byKey(SettingsSearchResults.emptyKey), findsNothing);
  });

  testWidgets('tapping a row selects its location', (tester) async {
    final matches = searchSettings('player 2 start');
    final selected = await pumpResults(tester, matches);

    await tester.tap(
      find.byKey(SettingsSearchResults.rowKey(matches.first.id)),
    );
    await tester.pumpAndSettle();

    expect(selected, [matches.first]);
  });

  testWidgets('rows are focusable', (tester) async {
    final matches = searchSettings('player 2 start');

    await pumpResults(tester, matches);

    final row = find.byKey(SettingsSearchResults.rowKey(matches.first.id));
    final inkWell = find.descendant(of: row, matching: find.byType(InkWell));

    expect(tester.widget<InkWell>(inkWell).canRequestFocus, isTrue);
  });

  testWidgets('no matches shows the empty state', (tester) async {
    await pumpResults(tester, const []);

    expect(find.byKey(SettingsSearchResults.emptyKey), findsOneWidget);
    expect(find.text('No matches'), findsOneWidget);
  });
}
