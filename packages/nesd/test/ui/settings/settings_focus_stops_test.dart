import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/navigation/settings_category_content.dart';
import 'package:nesd/ui/settings/navigation/settings_group_tile.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

import '../../helpers/focus.dart';
import '../robot.dart';

const bindingGroupIds = [
  'controls.bindings.menu',
  'controls.bindings.emulator',
  'controls.bindings.player1',
  'controls.bindings.player2',
  'controls.bindings.saveStates',
  'controls.bindings.tools',
];

void main() {
  for (final twoPane in [true, false]) {
    final layout = twoPane ? 'two-pane' : 'stacked';

    for (final category in SettingsCategory.values) {
      testWidgets('$layout ${category.name}: one focus stop per tile', (
        tester,
      ) async {
        final r = Robot(tester);

        await r.pumpApp(
          logicalSize: twoPane ? const Size(1920, 1080) : const Size(600, 1000),
        );
        await r.mainMenu.tapSettingsButton();
        await r.settingsScreen.openCategory(category);

        for (final group in bindingGroupIds) {
          if (find
              .byKey(SettingsGroupTile.headerKey(group))
              .evaluate()
              .isNotEmpty) {
            await r.settingsScreen.expandBindingGroup(group);
          }
        }

        final content = find.byType(SettingsCategoryContent);
        final tiles = find.descendant(
          of: content,
          matching: find.byWidgetPredicate(
            (w) => w is SettingsTile && w.enabled,
          ),
        );

        expect(tiles, findsWidgets);
        expect(
          traversableInside(tester, content).length,
          tiles.evaluate().length,
          reason: 'disabled tiles are skipped, every enabled tile is one stop',
        );

        for (final tile in tiles.evaluate()) {
          final tileFinder = find.byElementPredicate((e) => identical(e, tile));

          expect(
            traversableInside(tester, tileFinder).length,
            1,
            reason: 'exactly one focus stop for $tile',
          );
        }
      });
    }
  }
}
