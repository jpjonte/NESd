import 'package:flutter/material.dart' hide AboutDialog;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/palette/palette_selection.dart';
import 'package:nesd/ui/about/about_dialog.dart';
import 'package:nesd/ui/file_picker/file_system/memory_storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_edit_button.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_import_button.dart';
import 'package:nesd/ui/settings/navigation/settings_category_content.dart';
import 'package:nesd/ui/settings/navigation/settings_category_list.dart';
import 'package:nesd/ui/settings/navigation/settings_category_page.dart';
import 'package:nesd/ui/settings/navigation/settings_group_tile.dart';
import 'package:nesd/ui/settings/navigation/settings_nav_pane.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';
import 'package:nesd/ui/settings/settings_screen.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:nesd/ui/theme/light.dart';
import 'package:riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fonts.dart';
import '../base_robot.dart';
import 'controls/controls_settings_robot.dart';
import 'debug/debug_settings_robot.dart';

class SettingsScreenRobot extends BaseRobot {
  SettingsScreenRobot(super.tester)
    : debug = DebugSettingsRobot(tester),
      controls = ControlsSettingsRobot(tester);

  final ControlsSettingsRobot controls;
  final DebugSettingsRobot debug;

  Future<void> pumpSettingsScreen({List<Override> overrides = const []}) async {
    tester.view.physicalSize =
        const Size(1920, 1080) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await loadAppFonts();

    SharedPreferences.setMockInitialValues({});

    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          storageFilesystemProvider.overrideWithValue(
            MemoryStorageFilesystem(),
          ),
          ...overrides,
        ],
        child: MaterialApp(theme: nesdThemeLight, home: const SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  ProviderContainer get container =>
      ProviderScope.containerOf(tester.element(find.byType(SettingsScreen)));

  void expectSettingsScreenFound() {
    expect(find.byType(SettingsScreen), findsOneWidget);
  }

  void expectAboutDialogFound() {
    expectOne(find.byType(AboutDialog));
  }

  Future<void> tapAboutButton() async {
    await go(find.text('About NESd'));
  }

  Future<void> openCategory(SettingsCategory category) async {
    final navItem = find.byKey(SettingsNavPane.itemKey(category));

    if (navItem.evaluate().isNotEmpty) {
      await tester.ensureVisible(navItem);
      await go(navItem);

      return;
    }

    final row = find.byKey(SettingsCategoryList.rowKey(category));

    await tester.ensureVisible(row);
    await go(row);
  }

  void expectCategoryShown(SettingsCategory category) {
    expectOne(
      find.byWidgetPredicate(
        (w) => w is SettingsCategoryContent && w.category == category,
      ),
    );
  }

  void expectCategoriesListed() {
    for (final category in SettingsCategory.values) {
      final navItem = find.byKey(SettingsNavPane.itemKey(category));
      final row = find.byKey(SettingsCategoryList.rowKey(category));

      expect(
        navItem.evaluate().isNotEmpty || row.evaluate().isNotEmpty,
        isTrue,
        reason: '${category.name} is neither a nav item nor a list row',
      );
    }
  }

  Future<void> expandBindingGroup(String groupId) async {
    final header = find.byKey(SettingsGroupTile.headerKey(groupId));

    await tester.ensureVisible(header);
    await go(header);
  }

  Future<void> tapSectionChip(String sectionId) async {
    final chip = find.byKey(SettingsCategoryPage.chipKey(sectionId));

    await tester.ensureVisible(chip);
    await go(chip);
  }

  Future<void> selectPalette(NesPaletteId id) async {
    await go(find.byType(DropdownButton<PaletteSelection>));
    await go(find.text(id.displayName).last);
  }

  Future<void> selectUserPalette(String name) async {
    await go(find.byType(DropdownButton<PaletteSelection>));
    await go(find.text(name).last);
  }

  Future<void> tapImportPalette() async {
    final finder = find.byType(PaletteImportButton);

    await tester.ensureVisible(finder);
    await go(finder);
  }

  Future<void> tapEditPalette() async {
    final finder = find.byType(PaletteEditButton);

    await tester.ensureVisible(finder);
    await go(finder);
  }

  Future<void> tapRemovePalette() async {
    final finder = find.text('Remove palette');

    await tester.ensureVisible(finder);
    await go(finder);
  }

  Future<void> focusFirstCategory() async {
    const general = SettingsCategory.general;

    final navItem = find.byKey(SettingsNavPane.itemKey(general));
    final row = find.byKey(SettingsCategoryList.rowKey(general));

    await expectAndFocus(navItem.evaluate().isNotEmpty ? navItem : row);
  }
}
