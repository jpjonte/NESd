import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/memory_storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:nesd/ui/settings/controls/binding_tile.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_dropdown.dart';
import 'package:nesd/ui/settings/navigation/settings_category_content.dart';
import 'package:nesd/ui/settings/navigation/settings_nav_pane.dart';
import 'package:nesd/ui/settings/navigation/settings_navigation.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';
import 'package:nesd/ui/settings/navigation/two_pane_settings.dart';
import 'package:nesd/ui/settings/search/settings_search_field.dart';
import 'package:nesd/ui/settings/search/settings_search_results.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:nesd/ui/theme/light.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/focus.dart';
import '../../../helpers/fonts.dart';

class _FakeFilesystem extends Mock implements Filesystem {}

void main() {
  Finder content(SettingsCategory category) => find.byWidgetPredicate(
    (w) => w is SettingsCategoryContent && w.category == category,
  );

  Finder section(String id) => find.byWidgetPredicate(
    (w) => w is SettingsSectionView && w.section.id == id,
  );

  Finder navItem(SettingsCategory category) =>
      find.byKey(SettingsNavPane.itemKey(category));

  void invokeAt(WidgetTester tester, Finder where, Intent intent) =>
      Actions.invoke(tester.element(where), intent);

  var outerDismissals = 0;

  Future<ProviderContainer> pumpTwoPane(
    WidgetTester tester, {
    Size size = const Size(1920, 1080),
  }) async {
    outerDismissals = 0;

    SharedPreferences.setMockInitialValues({});

    final prefs = await SharedPreferences.getInstance();

    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await loadAppFonts();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          storageFilesystemProvider.overrideWithValue(
            MemoryStorageFilesystem(),
          ),
          filesystemProvider.overrideWithValue(_FakeFilesystem()),
        ],
        child: MaterialApp(
          theme: nesdThemeLight,
          home: Scaffold(
            body: Actions(
              actions: {
                DismissIntent: CallbackAction<DismissIntent>(
                  onInvoke: (_) => outerDismissals++,
                ),
              },
              child: const TwoPaneSettings(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return ProviderScope.containerOf(
      tester.element(find.byType(TwoPaneSettings)),
    );
  }

  testWidgets('lists every category plus About and shows General', (
    tester,
  ) async {
    await pumpTwoPane(tester);

    for (final category in SettingsCategory.values) {
      expect(find.byKey(SettingsNavPane.itemKey(category)), findsOneWidget);
    }

    expect(find.byKey(SettingsNavPane.aboutKey), findsOneWidget);
    expect(content(SettingsCategory.general), findsOneWidget);
    expect(
      focusInside(
        tester,
        find.byKey(SettingsNavPane.itemKey(SettingsCategory.general)),
      ),
      isTrue,
      reason: 'the selected nav item takes focus on open',
    );
  });

  testWidgets('the panes are sized and the pair is centred', (tester) async {
    await pumpTwoPane(tester);

    const paneWidth = SettingsNavPane.width;
    const contentWidth = TwoPaneSettings.contentMaxWidth;

    expect(tester.getSize(find.byType(SettingsNavPane)).width, paneWidth);

    final navScrollers = find
        .descendant(
          of: find.byType(SettingsNavPane),
          matching: find.byType(SingleChildScrollView),
        )
        .evaluate()
        .toSet();

    final contentScroller = find
        .descendant(
          of: find.byType(TwoPaneSettings),
          matching: find.byType(SingleChildScrollView),
        )
        .evaluate()
        .firstWhere((e) => !navScrollers.contains(e));

    expect(contentScroller.size?.width, contentWidth);
    expect(
      tester.getRect(find.byType(SettingsNavPane)).left,
      (1920 - (paneWidth + contentWidth)) / 2,
    );
  });

  testWidgets('single-section categories have no section links', (
    tester,
  ) async {
    await pumpTwoPane(tester);

    expect(
      find.byKey(SettingsNavPane.sectionKey('video.palette')),
      findsOneWidget,
    );
    expect(
      find.byKey(SettingsNavPane.sectionKey('advanced.main')),
      findsNothing,
    );
  });

  testWidgets('tapping a category shows it and moves focus into content', (
    tester,
  ) async {
    final container = await pumpTwoPane(tester);

    await tester.tap(
      find.byKey(SettingsNavPane.itemKey(SettingsCategory.video)),
    );
    await tester.pumpAndSettle();

    expect(content(SettingsCategory.video), findsOneWidget);
    expect(
      container.read(settingsNavigationProvider).category,
      SettingsCategory.video,
    );
    expect(
      focusInside(tester, content(SettingsCategory.video)),
      isTrue,
      reason: 'confirm on a category enters the content pane',
    );
  });

  testWidgets('a section link scrolls the section in and focuses it', (
    tester,
  ) async {
    await pumpTwoPane(tester);

    await tester.tap(find.byKey(SettingsNavPane.sectionKey('video.palette')));
    await tester.pumpAndSettle();

    expect(content(SettingsCategory.video), findsOneWidget);

    final palette = section('video.palette');
    final viewport = tester.getRect(find.byType(TwoPaneSettings));

    expect(tester.getRect(palette).top, greaterThanOrEqualTo(viewport.top));
    expect(
      tester.getRect(find.byType(PaletteDropdown)).top,
      lessThan(viewport.bottom),
    );
    expect(focusInside(tester, palette), isTrue);
  });

  testWidgets('tab intents cycle categories and focus the nav item', (
    tester,
  ) async {
    final container = await pumpTwoPane(tester);

    Actions.invoke(
      tester.element(
        find.byKey(SettingsNavPane.itemKey(SettingsCategory.general)),
      ),
      const NextTabIntent(),
    );
    await tester.pumpAndSettle();

    expect(
      container.read(settingsNavigationProvider).category,
      SettingsCategory.video,
    );
    expect(
      focusInside(
        tester,
        find.byKey(SettingsNavPane.itemKey(SettingsCategory.video)),
      ),
      isTrue,
    );

    Actions.invoke(
      tester.element(
        find.byKey(SettingsNavPane.itemKey(SettingsCategory.video)),
      ),
      const PreviousTabIntent(),
    );
    Actions.invoke(
      tester.element(
        find.byKey(SettingsNavPane.itemKey(SettingsCategory.video)),
      ),
      const PreviousTabIntent(),
    );
    await tester.pumpAndSettle();

    expect(
      container.read(settingsNavigationProvider).category,
      SettingsCategory.advanced,
      reason: 'previous from General wraps to the last category',
    );
  });

  testWidgets('a short window scrolls the stepped-to nav item into view', (
    tester,
  ) async {
    await pumpTwoPane(tester, size: const Size(900, 420));

    Actions.invoke(
      tester.element(
        find.byKey(SettingsNavPane.itemKey(SettingsCategory.general)),
      ),
      const PreviousTabIntent(),
    );
    await tester.pumpAndSettle();

    final item = find.byKey(SettingsNavPane.itemKey(SettingsCategory.advanced));

    expect(
      focusInside(tester, item),
      isTrue,
      reason: 'the wrapped-to nav item must exist and take focus',
    );

    final pane = tester.getRect(find.byType(SettingsNavPane));
    final rect = tester.getRect(item);

    expect(rect.top, greaterThanOrEqualTo(pane.top));
    expect(rect.bottom, lessThanOrEqualTo(pane.bottom));
  });

  const startId = 'controls.bindings.player2/Controller 2 Start';

  final searchField = find.byKey(SettingsSearchField.fieldKey);

  Finder bindingTile(String title) => find.byWidgetPredicate(
    (w) => w is BindingTile && w.action.title == title,
  );

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(searchField, query);
    await tester.pumpAndSettle();
  }

  testWidgets('typing replaces the nav list with results', (tester) async {
    final container = await pumpTwoPane(tester);

    await search(tester, 'player 2 start');

    expect(container.read(settingsNavigationProvider).query, 'player 2 start');
    expect(find.byKey(SettingsSearchResults.rowKey(startId)), findsOneWidget);
    expect(
      find.byKey(SettingsNavPane.itemKey(SettingsCategory.general)),
      findsNothing,
    );
    expect(find.byKey(SettingsNavPane.aboutKey), findsNothing);
    expect(content(SettingsCategory.general), findsOneWidget);

    await tester.tap(find.byKey(SettingsSearchField.clearKey));
    await tester.pumpAndSettle();

    expect(container.read(settingsNavigationProvider).query, '');
    expect(find.byType(SettingsSearchResults), findsNothing);
    expect(
      find.byKey(SettingsNavPane.itemKey(SettingsCategory.general)),
      findsOneWidget,
    );
  });

  testWidgets('a result opens its category, expands the group and focuses it', (
    tester,
  ) async {
    final container = await pumpTwoPane(tester);

    await search(tester, 'player 2 start');
    await tester.tap(find.byKey(SettingsSearchResults.rowKey(startId)));
    await tester.pumpAndSettle();

    final navigation = container.read(settingsNavigationProvider);

    expect(navigation.category, SettingsCategory.controls);
    expect(navigation.expandedGroups, contains('controls.bindings.player2'));
    expect(navigation.query, 'player 2 start', reason: 'results stay');

    final tile = bindingTile('Controller 2 Start');
    final viewport = tester.getRect(find.byType(TwoPaneSettings));

    expect(tile, findsOneWidget);
    expect(tester.getRect(tile).top, greaterThanOrEqualTo(viewport.top));
    expect(tester.getRect(tile).bottom, lessThanOrEqualTo(viewport.bottom));
    expect(focusInside(tester, tile), isTrue);
  });

  testWidgets('submitting the field selects the top result', (tester) async {
    final container = await pumpTwoPane(tester);

    await search(tester, 'timer');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(
      container.read(settingsNavigationProvider).category,
      SettingsCategory.general,
    );
    expect(focusInside(tester, section('general.saves')), isTrue);
  });

  testWidgets('a hidden entry is not offered as a result', (tester) async {
    await pumpTwoPane(tester);

    await search(tester, 'saturation');

    expect(
      find.byKey(SettingsSearchResults.rowKey('video.palette/Saturation')),
      findsNothing,
      reason:
          'the palette sliders are hidden until a generated palette is '
          'selected',
    );
  });

  testWidgets('dismiss clears the query, then leaves', (tester) async {
    final container = await pumpTwoPane(tester);

    await search(tester, 'start');

    Actions.invoke(tester.element(searchField), const DismissIntent());
    await tester.pumpAndSettle();

    expect(container.read(settingsNavigationProvider).query, '');
    expect(find.byType(TwoPaneSettings), findsOneWidget);
  });

  testWidgets('right on a nav item enters the content', (tester) async {
    await pumpTwoPane(tester);

    focusInto(tester, navItem(SettingsCategory.general));
    await tester.pumpAndSettle();

    invokeAt(
      tester,
      navItem(SettingsCategory.general),
      const DirectionalFocusIntent(TraversalDirection.right),
    );
    await tester.pumpAndSettle();

    expect(focusInside(tester, content(SettingsCategory.general)), isTrue);
  });

  testWidgets('left on a plain tile returns to the nav item', (tester) async {
    await pumpTwoPane(tester);

    final firstTile = find
        .descendant(
          of: content(SettingsCategory.general),
          matching: find.byType(SettingsTile),
        )
        .first;

    focusInto(tester, firstTile);
    await tester.pumpAndSettle();

    invokeAt(
      tester,
      firstTile,
      const DirectionalFocusIntent(TraversalDirection.left),
    );
    await tester.pumpAndSettle();

    expect(focusInside(tester, navItem(SettingsCategory.general)), isTrue);
  });

  testWidgets('the content remembers its last tile', (tester) async {
    await pumpTwoPane(tester);

    final tiles = find.descendant(
      of: content(SettingsCategory.general),
      matching: find.byType(SettingsTile),
    );

    focusInto(tester, tiles.at(2));
    await tester.pumpAndSettle();

    invokeAt(tester, tiles.at(2), const DismissIntent());
    await tester.pumpAndSettle();

    expect(focusInside(tester, navItem(SettingsCategory.general)), isTrue);
    expect(outerDismissals, 0);

    invokeAt(
      tester,
      navItem(SettingsCategory.general),
      const DirectionalFocusIntent(TraversalDirection.right),
    );
    await tester.pumpAndSettle();

    expect(focusInside(tester, tiles.at(2)), isTrue);
  });

  testWidgets('dismiss on the nav pane bubbles up', (tester) async {
    await pumpTwoPane(tester);

    focusInto(tester, navItem(SettingsCategory.general));
    await tester.pumpAndSettle();

    invokeAt(tester, navItem(SettingsCategory.general), const DismissIntent());

    expect(outerDismissals, 1);
  });

  testWidgets('down from the last tile wraps inside the content', (
    tester,
  ) async {
    await pumpTwoPane(tester);

    final tiles = find.descendant(
      of: content(SettingsCategory.general),
      matching: find.byType(SettingsTile),
    );

    focusInto(tester, tiles.last);
    await tester.pumpAndSettle();

    invokeAt(
      tester,
      tiles.last,
      const DirectionalFocusIntent(TraversalDirection.down),
    );
    await tester.pumpAndSettle();

    expect(focusInside(tester, tiles.first), isTrue);
    expect(focusInside(tester, find.byType(SettingsNavPane)), isFalse);
  });

  Finder resultRows() => find.descendant(
    of: find.byType(SettingsSearchResults),
    matching: find.byType(InkWell),
  );

  testWidgets('left from a found entry returns to its search result', (
    tester,
  ) async {
    await pumpTwoPane(tester);

    await search(tester, 'player 2 start');
    await tester.tap(find.byKey(SettingsSearchResults.rowKey(startId)));
    await tester.pumpAndSettle();

    final tile = bindingTile('Controller 2 Start');

    expect(focusInside(tester, tile), isTrue);

    invokeAt(
      tester,
      tile,
      const DirectionalFocusIntent(TraversalDirection.left),
    );
    await tester.pumpAndSettle();

    expect(
      focusInside(tester, find.byKey(SettingsSearchResults.rowKey(startId))),
      isTrue,
    );
  });

  testWidgets('dismiss from a found entry returns to its search result', (
    tester,
  ) async {
    await pumpTwoPane(tester);

    await search(tester, 'player 2 start');
    await tester.tap(find.byKey(SettingsSearchResults.rowKey(startId)));
    await tester.pumpAndSettle();

    invokeAt(tester, bindingTile('Controller 2 Start'), const DismissIntent());
    await tester.pumpAndSettle();

    expect(
      focusInside(tester, find.byKey(SettingsSearchResults.rowKey(startId))),
      isTrue,
    );
    expect(outerDismissals, 0);
  });

  testWidgets('the selected result is the one that gets focus back', (
    tester,
  ) async {
    await pumpTwoPane(tester);

    await search(tester, 'player');

    expect(resultRows(), findsAtLeastNWidgets(2));

    await tester.tap(resultRows().at(1));
    await tester.pumpAndSettle();

    final focused = FocusManager.instance.primaryFocus!.context!;

    expect(
      focusInside(tester, find.byType(SettingsNavPane)),
      isFalse,
      reason: 'selecting a result moves focus into the content',
    );

    Actions.invoke(
      focused,
      const DirectionalFocusIntent(TraversalDirection.left),
    );
    await tester.pumpAndSettle();

    expect(focusInside(tester, resultRows().at(1)), isTrue);
  });

  testWidgets('dismiss on a search result clears the search', (tester) async {
    final container = await pumpTwoPane(tester);

    await search(tester, 'player 2 start');

    final row = find.byKey(SettingsSearchResults.rowKey(startId));

    focusInto(tester, row);
    await tester.pumpAndSettle();

    invokeAt(tester, row, const DismissIntent());
    await tester.pumpAndSettle();

    expect(container.read(settingsNavigationProvider).query, isEmpty);
    expect(find.byType(SettingsSearchResults), findsNothing);
    expect(focusInside(tester, navItem(SettingsCategory.general)), isTrue);
    expect(outerDismissals, 0);
  });
}
