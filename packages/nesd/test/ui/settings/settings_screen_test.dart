import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/audio/low_pass_filter_switch.dart';
import 'package:nesd/ui/settings/audio/swap_duty_cycles_switch.dart';
import 'package:nesd/ui/settings/debug/debug_overlay_switch.dart';
import 'package:nesd/ui/settings/navigation/settings_category_content.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

import '../robot.dart';

void main() {
  testWidgets('Settings screen opens on General with every category listed', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();
    r.settingsScreen.expectSettingsScreenFound();
    r.settingsScreen.expectCategoriesListed();
    r.settingsScreen.expectCategoryShown(SettingsCategory.general);
  });

  testWidgets('About dialog can be opened from the settings navigation', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.tapAboutButton();
    r.settingsScreen.expectAboutDialogFound();
  });

  testWidgets('Video category shows its four sections', (tester) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.openCategory(SettingsCategory.video);
    r.settingsScreen.expectCategoryShown(SettingsCategory.video);

    expect(find.text('Display'), findsWidgets);
    expect(find.text('Aspect & Overscan'), findsWidgets);
    expect(find.text('Palette'), findsWidgets);
    expect(find.text('Filters'), findsWidgets);
  });

  testWidgets('Audio category', (tester) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.openCategory(SettingsCategory.audio);

    await r.expectSwitch(
      find.byType(LowPassFilterSwitch),
      getValue: () => r.settings.lowPassFilter,
    );

    await r.expectSwitch(
      find.byType(SwapDutyCyclesSwitch),
      getValue: () => r.settings.swapDutyCycles,
    );

    expect(find.text('Pulse 1'), findsOneWidget);
    expect(find.text('Namco 163'), findsOneWidget);
  });

  testWidgets('Controls category', (tester) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.openCategory(SettingsCategory.controls);
    r.settingsScreen.controls.expectControlsSettingsFound();
  });

  testWidgets('Advanced category', (tester) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.openCategory(SettingsCategory.advanced);
    r.settingsScreen.debug.expectDebugSettingsFound();

    await r.expectSwitch(
      find.byType(DebugOverlaySwitch),
      getValue: () => r.settings.showDebugOverlay,
    );

    expect(
      find.descendant(
        of: find.byWidgetPredicate(
          (w) =>
              w is SettingsCategoryContent &&
              w.category == SettingsCategory.advanced,
        ),
        matching: find.byType(SwitchSettingsTile),
      ),
      findsOneWidget,
    );
  });
}
