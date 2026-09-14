import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/settings/navigation/settings_navigation.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';
import 'package:nesd/ui/settings/search/settings_search_field.dart';
import 'package:nesd/ui/settings/settings_screen.dart';

import '../../helpers/focus.dart';
import '../robot.dart';

const _rom = {
  'recentRoms': [
    {
      'file': {
        'path': '/test/roms/nestest.nes',
        'name': '/test/roms/nestest.nes',
        'type': 'file',
      },
    },
  ],
};

void main() {
  testWidgets('Tab steps to the next category through the bindings', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();

    await r.pressKey(LogicalKeyboardKey.tab);

    expect(
      r.container.read(settingsNavigationProvider).category,
      SettingsCategory.video,
    );
  });

  testWidgets('the search field keeps Backspace and gives up Down', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();

    final field = find.byKey(SettingsSearchField.fieldKey);

    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, 'vol');
    await tester.pumpAndSettle();

    await r.pressKey(LogicalKeyboardKey.backspace);

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(r.container.read(settingsNavigationProvider).query, 'vo');

    await r.pressKey(LogicalKeyboardKey.arrowDown);

    expect(focusInside(tester, field), isFalse);
  });

  testWidgets('Escape in settings returns to the pause menu', (tester) async {
    final r = Robot(tester)..initSettings(_rom);

    await r.pumpApp();
    await r.mainMenu.tapFirstRomTile();
    r.emulator.expectEmulatorWidgetFound();
    await r.emulator.tapMenu();
    await r.pumpFrames(const Duration(milliseconds: 500));
    await r.menuScreen.tapSettings();
    r.settingsScreen.expectSettingsScreenFound();

    await r.pressKey(LogicalKeyboardKey.escape);

    expect(find.byType(SettingsScreen), findsNothing);
    r.menuScreen.expectMenuScreenFound();

    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });
}
