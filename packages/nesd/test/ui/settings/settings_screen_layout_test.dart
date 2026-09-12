import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/settings/controls/binding_tile.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_dropdown.dart';
import 'package:nesd/ui/settings/navigation/settings_category_content.dart';
import 'package:nesd/ui/settings/navigation/settings_category_list.dart';
import 'package:nesd/ui/settings/navigation/settings_category_page.dart';
import 'package:nesd/ui/settings/navigation/settings_nav_pane.dart';
import 'package:nesd/ui/settings/navigation/settings_navigation.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';
import 'package:nesd/ui/settings/navigation/two_pane_settings.dart';
import 'package:nesd/ui/settings/search/settings_search_field.dart';
import 'package:nesd/ui/settings/search/settings_search_results.dart';
import 'package:nesd/ui/settings/settings_screen.dart';

import '../../helpers/focus.dart';
import '../robot.dart';

const _phone = Size(400, 800);
const _desktop = Size(1920, 1080);

void main() {
  Future<Robot> openSettings(WidgetTester tester, Size size) async {
    final r = Robot(tester);

    await r.pumpApp(logicalSize: size);
    await r.mainMenu.tapSettingsButton();
    r.settingsScreen.expectSettingsScreenFound();

    return r;
  }

  Future<void> resize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size * tester.view.devicePixelRatio;

    await tester.pumpAndSettle();
  }

  Finder appBarTitle(String text) =>
      find.descendant(of: find.byType(AppBar), matching: find.text(text));

  Finder section(String id) => find.byWidgetPredicate(
    (w) => w is SettingsSectionView && w.section.id == id,
  );

  testWidgets('a phone-sized window opens on the category list', (
    tester,
  ) async {
    final r = await openSettings(tester, _phone);

    expect(find.byType(SettingsCategoryList), findsOneWidget);
    expect(find.byType(TwoPaneSettings), findsNothing);
    expect(appBarTitle('Settings'), findsOneWidget);

    await r.settingsScreen.openCategory(SettingsCategory.video);

    expect(find.byType(SettingsCategoryPage), findsOneWidget);
    expect(appBarTitle('Video'), findsOneWidget);
    r.settingsScreen.expectCategoryShown(SettingsCategory.video);

    await r.settingsScreen.tapSectionChip('video.palette');

    expect(find.byType(PaletteDropdown), findsOneWidget);
    expect(
      tester.getRect(find.byType(PaletteDropdown)).bottom,
      lessThanOrEqualTo(_phone.height),
      reason: 'the chip scrolled the section into the viewport',
    );
    expect(focusInside(tester, section('video.palette')), isTrue);
  });

  testWidgets('cancel goes back to the list, then leaves settings', (
    tester,
  ) async {
    final r = await openSettings(tester, _phone);

    await r.settingsScreen.openCategory(SettingsCategory.video);

    r.sendInputAction(cancel);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsCategoryList), findsOneWidget);
    expect(appBarTitle('Settings'), findsOneWidget);

    r.sendInputAction(cancel);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsNothing);
  });

  testWidgets('bumpers cycle categories on a two-pane layout', (tester) async {
    final r = await openSettings(tester, _desktop);

    r.sendInputAction(nextTab);
    await tester.pumpAndSettle();

    r.settingsScreen.expectCategoryShown(SettingsCategory.video);
    expect(
      focusInside(
        tester,
        find.byKey(SettingsNavPane.itemKey(SettingsCategory.video)),
      ),
      isTrue,
    );

    r
      ..sendInputAction(previousTab)
      ..sendInputAction(previousTab);
    await tester.pumpAndSettle();

    r.settingsScreen.expectCategoryShown(SettingsCategory.advanced);
  });

  testWidgets('bumpers switch pages on a stacked layout', (tester) async {
    final r = await openSettings(tester, _phone);

    r.sendInputAction(nextTab);
    await tester.pumpAndSettle();

    expect(
      find.byType(SettingsCategoryList),
      findsOneWidget,
      reason: 'bumpers do nothing on the list',
    );

    await r.settingsScreen.openCategory(SettingsCategory.video);

    r.sendInputAction(nextTab);
    await tester.pumpAndSettle();

    r.settingsScreen.expectCategoryShown(SettingsCategory.audio);
    expect(appBarTitle('Audio'), findsOneWidget);
  });

  testWidgets('crossing the breakpoint keeps the selected category', (
    tester,
  ) async {
    final r = await openSettings(tester, _desktop);

    await r.settingsScreen.openCategory(SettingsCategory.video);

    await resize(tester, _phone);

    expect(find.byType(SettingsCategoryPage), findsOneWidget);
    r.settingsScreen.expectCategoryShown(SettingsCategory.video);

    await resize(tester, _desktop);

    expect(find.byType(TwoPaneSettings), findsOneWidget);
    r.settingsScreen.expectCategoryShown(SettingsCategory.video);
  });

  testWidgets('reopening settings starts fresh', (tester) async {
    final r = await openSettings(tester, _phone);

    await r.settingsScreen.openCategory(SettingsCategory.video);

    r.sendInputAction(cancel);
    await tester.pumpAndSettle();
    r.sendInputAction(cancel);
    await tester.pumpAndSettle();

    await r.mainMenu.tapSettingsButton();

    expect(find.byType(SettingsCategoryList), findsOneWidget);
  });

  testWidgets('the About entry opens the dialog on a stacked layout', (
    tester,
  ) async {
    final r = await openSettings(tester, _phone);

    await r.settingsScreen.tapAboutButton();
    r.settingsScreen.expectAboutDialogFound();
  });

  testWidgets('D-pad left from the content returns to the nav pane', (
    tester,
  ) async {
    final r = await openSettings(tester, _desktop);

    await r.settingsScreen.openCategory(SettingsCategory.audio);

    expect(
      focusInside(tester, find.byType(TwoPaneSettings)),
      isTrue,
      reason: 'selecting a category moves focus into the content',
    );
    expect(focusInside(tester, find.byType(SettingsNavPane)), isFalse);

    r.sendInputAction(inputLeft);
    await tester.pumpAndSettle();

    expect(focusInside(tester, find.byType(SettingsNavPane)), isTrue);
  });

  testWidgets(
    'every category renders two-pane at the 720 px breakpoint without '
    'overflow',
    (tester) async {
      final r = await openSettings(tester, const Size(720, 800));

      expect(find.byType(TwoPaneSettings), findsOneWidget);

      for (final category in SettingsCategory.values) {
        await r.settingsScreen.openCategory(category);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: category.name);
      }
    },
  );

  const startId = 'controls.bindings.player2/Controller 2 Start';

  final searchField = find.byKey(SettingsSearchField.fieldKey);

  Finder bindingTile(String title) => find.byWidgetPredicate(
    (w) => w is BindingTile && w.action.title == title,
  );

  for (final (name, size) in [('desktop', _desktop), ('phone', _phone)]) {
    testWidgets('$name: the d-pad reaches the search, results and entry', (
      tester,
    ) async {
      final r = await openSettings(tester, size);

      r.sendInputAction(inputUp);
      await tester.pumpAndSettle();

      expect(
        focusInside(tester, searchField),
        isTrue,
        reason: 'up from the first navigation item enters the field',
      );

      await tester.enterText(searchField, 'player 2 start');
      await tester.pumpAndSettle();

      r.sendInputAction(inputDown);
      await tester.pumpAndSettle();

      final row = find.byKey(SettingsSearchResults.rowKey(startId));

      expect(focusInside(tester, row), isTrue, reason: 'down leaves the field');

      r.sendInputAction(confirm);
      await tester.pumpAndSettle();

      final tile = bindingTile('Controller 2 Start');

      expect(tile, findsOneWidget);
      expect(tester.getRect(tile).bottom, lessThanOrEqualTo(size.height));
      expect(focusInside(tester, tile), isTrue);
    });
  }

  testWidgets('crossing the breakpoint mid-search keeps the field focused', (
    tester,
  ) async {
    final r = await openSettings(tester, _phone);

    await tester.enterText(searchField, 'player 2 start');
    await tester.pumpAndSettle();

    await resize(tester, _desktop);

    expect(find.byType(TwoPaneSettings), findsOneWidget);
    expect(
      r.settingsScreen.container.read(settingsNavigationProvider).query,
      'player 2 start',
    );
    expect(find.byKey(SettingsSearchResults.rowKey(startId)), findsOneWidget);
    expect(focusInside(tester, searchField), isTrue);
  });

  testWidgets('cancel in the field clears the query, then leaves settings', (
    tester,
  ) async {
    final r = await openSettings(tester, _desktop);

    await tester.enterText(searchField, 'start');
    await tester.pumpAndSettle();

    r.sendInputAction(cancel);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsSearchResults), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(focusInside(tester, searchField), isTrue);

    r.sendInputAction(cancel);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsNothing);
  });
}
