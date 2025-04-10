import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/settings/debug/cartridge_switch.dart';
import 'package:nesd/ui/settings/debug/debug_overlay_switch.dart';
import 'package:nesd/ui/settings/debug/debug_tile_switch.dart';
import 'package:nesd/ui/settings/debug/debugger_switch.dart';

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

    // TODO
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
      find.byType(DebugTileSwitch),
      getValue: () => r.settings.showTiles,
    );

    await r.expectSwitch(
      find.byType(CartridgeSwitch),
      getValue: () => r.settings.showCartridgeInfo,
    );

    await r.expectSwitch(
      find.byType(DebugOverlaySwitch),
      getValue: () => r.settings.showDebugOverlay,
    );

    await r.expectSwitch(
      find.byType(DebuggerSwitch),
      getValue: () => r.settings.showDebugger,
    );
  });
}
