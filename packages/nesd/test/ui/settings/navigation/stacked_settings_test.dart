import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/file_picker/file_system/memory_storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_dropdown.dart';
import 'package:nesd/ui/settings/navigation/settings_category_content.dart';
import 'package:nesd/ui/settings/navigation/settings_category_list.dart';
import 'package:nesd/ui/settings/navigation/settings_category_page.dart';
import 'package:nesd/ui/settings/navigation/settings_navigation.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';
import 'package:nesd/ui/settings/navigation/stacked_settings.dart';
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

  Future<ProviderContainer> pumpStacked(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    final prefs = await SharedPreferences.getInstance();

    tester.view.physicalSize =
        const Size(400, 800) * tester.view.devicePixelRatio;
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
          home: const Scaffold(body: StackedSettings()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return ProviderScope.containerOf(
      tester.element(find.byType(StackedSettings)),
    );
  }

  Future<void> openCategory(
    WidgetTester tester,
    SettingsCategory category,
  ) async {
    await tester.tap(find.byKey(SettingsCategoryList.rowKey(category)));
    await tester.pumpAndSettle();
  }

  testWidgets('starts on the category list with section subtitles', (
    tester,
  ) async {
    await pumpStacked(tester);

    for (final category in SettingsCategory.values) {
      expect(find.byKey(SettingsCategoryList.rowKey(category)), findsOneWidget);
    }

    expect(find.byKey(SettingsCategoryList.aboutKey), findsOneWidget);
    expect(find.text('Saves · Emulation · Appearance'), findsOneWidget);
    expect(find.byType(SettingsCategoryPage), findsNothing);
    expect(
      focusInside(
        tester,
        find.byKey(SettingsCategoryList.rowKey(SettingsCategory.general)),
      ),
      isTrue,
    );
  });

  testWidgets('a row opens the category page with section chips', (
    tester,
  ) async {
    final container = await pumpStacked(tester);

    await openCategory(tester, SettingsCategory.video);

    expect(find.byType(SettingsCategoryList), findsNothing);
    expect(content(SettingsCategory.video), findsOneWidget);
    expect(
      find.byKey(SettingsCategoryPage.chipKey('video.palette')),
      findsOneWidget,
    );
    expect(
      container.read(settingsNavigationProvider).category,
      SettingsCategory.video,
    );
    expect(
      focusInside(tester, content(SettingsCategory.video)),
      isTrue,
      reason: 'the page autofocuses its first tile',
    );
  });

  testWidgets('a single-section category has no chips', (tester) async {
    await pumpStacked(tester);

    await openCategory(tester, SettingsCategory.advanced);

    expect(find.byType(ActionChip), findsNothing);
    expect(content(SettingsCategory.advanced), findsOneWidget);
  });

  testWidgets('a chip scrolls its section into view and focuses it', (
    tester,
  ) async {
    await pumpStacked(tester);

    await openCategory(tester, SettingsCategory.video);

    final chip = find.byKey(SettingsCategoryPage.chipKey('video.palette'));

    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();

    final viewport = tester.getRect(find.byType(StackedSettings));

    expect(
      tester.getRect(find.byType(PaletteDropdown)).top,
      lessThan(viewport.bottom),
    );
    expect(focusInside(tester, section('video.palette')), isTrue);
  });

  testWidgets('popping the route returns to the list and refocuses the row', (
    tester,
  ) async {
    final container = await pumpStacked(tester);

    await openCategory(tester, SettingsCategory.video);

    final popped = await Navigator.of(
      tester.element(find.byType(SettingsCategoryPage)),
    ).maybePop();
    await tester.pumpAndSettle();

    expect(popped, isTrue, reason: 'PopScope consumed the pop');
    expect(find.byType(SettingsCategoryList), findsOneWidget);
    expect(container.read(settingsNavigationProvider).category, isNull);
    expect(
      focusInside(
        tester,
        find.byKey(SettingsCategoryList.rowKey(SettingsCategory.video)),
      ),
      isTrue,
    );
  });

  testWidgets('a category re-entered mid-animation keeps its own keys', (
    tester,
  ) async {
    await pumpStacked(tester);

    await openCategory(tester, SettingsCategory.video);

    final page = tester.element(find.byType(SettingsCategoryPage));

    Actions.invoke(page, const NextTabIntent());
    await tester.pump();

    Actions.invoke(page, const PreviousTabIntent());
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      tester.takeException(),
      isNull,
      reason: 'the outgoing page must not share section keys with the new one',
    );
    expect(content(SettingsCategory.video), findsOneWidget);
  });

  testWidgets('tab intents switch category pages but not the list', (
    tester,
  ) async {
    final container = await pumpStacked(tester);

    Actions.maybeInvoke(
      tester.element(
        find.byKey(SettingsCategoryList.rowKey(SettingsCategory.general)),
      ),
      const NextTabIntent(),
    );
    await tester.pumpAndSettle();

    expect(container.read(settingsNavigationProvider).category, isNull);

    await openCategory(tester, SettingsCategory.general);

    Actions.invoke(
      tester.element(content(SettingsCategory.general)),
      const NextTabIntent(),
    );
    await tester.pumpAndSettle();

    expect(content(SettingsCategory.video), findsOneWidget);
  });
}
