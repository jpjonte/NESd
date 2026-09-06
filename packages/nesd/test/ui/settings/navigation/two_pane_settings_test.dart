import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/file_picker/file_system/memory_storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:nesd/ui/settings/graphics/palette_dropdown.dart';
import 'package:nesd/ui/settings/navigation/settings_category_content.dart';
import 'package:nesd/ui/settings/navigation/settings_nav_pane.dart';
import 'package:nesd/ui/settings/navigation/settings_navigation.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';
import 'package:nesd/ui/settings/navigation/two_pane_settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:nesd/ui/theme/light.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/focus.dart';
import '../../../helpers/fonts.dart';

void main() {
  Finder content(SettingsCategory category) => find.byWidgetPredicate(
    (w) => w is SettingsCategoryContent && w.category == category,
  );

  Finder section(String id) => find.byWidgetPredicate(
    (w) => w is SettingsSectionView && w.section.id == id,
  );

  Future<ProviderContainer> pumpTwoPane(
    WidgetTester tester, {
    Size size = const Size(1920, 1080),
  }) async {
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
        ],
        child: MaterialApp(
          theme: nesdThemeLight,
          home: const Scaffold(body: TwoPaneSettings()),
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
}
