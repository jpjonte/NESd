import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/audio/low_pass_filter_switch.dart';
import 'package:nesd/ui/settings/debug/debug_overlay_switch.dart';
import 'package:nesd/ui/settings/debug/debug_settings.dart';

import '../robot.dart';

void main() {
  testWidgets('Settings screen can be opened and all tabs are present', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();
    r.settingsScreen.expectSettingsScreenFound();
    r.settingsScreen.expectTabHeadersFound();
    r.settingsScreen.expectGeneralTabFound();
  });

  testWidgets('About dialog can be opened from the General settings tab', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.tapAboutButton();
    r.settingsScreen.expectAboutDialogFound();
  });

  testWidgets('Test Graphics settings tab', (tester) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.tapGraphicsTab();

    // TODO
  });

  testWidgets('Test Audio settings tab', (tester) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.tapAudioTab();

    await r.expectSwitch(
      find.byType(LowPassFilterSwitch),
      getValue: () => r.settings.lowPassFilter,
    );
  });

  testWidgets('Test Controls settings tab', (tester) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.tapControlsTab();
    r.settingsScreen.controls.expectControlsSettingsFound();

    // await r.expectSwitch(
    //   find.byType(ShowTouchControlsSwitch),
    //   getValue: () => r.settings.showTouchControls,
    // );
  });

  testWidgets('Test Debug settings tab', (tester) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.tapDebugTab();
    r.settingsScreen.debug.expectDebugSettingsFound();

    await r.expectSwitch(
      find.byType(DebugOverlaySwitch),
      getValue: () => r.settings.showDebugOverlay,
    );

    expect(
      find.descendant(
        of: find.byType(DebugSettings),
        matching: find.byType(SwitchSettingsTile),
      ),
      findsOneWidget,
    );
  });
}
