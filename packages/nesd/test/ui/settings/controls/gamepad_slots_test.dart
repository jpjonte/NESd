import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_key.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_handler.dart';

import '../../robot.dart';

void main() {
  Future<Robot> openControlsTab(WidgetTester tester) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.tapControlsTab();

    return r;
  }

  testWidgets('shows a placeholder when no gamepad is detected', (
    tester,
  ) async {
    final r = await openControlsTab(tester);

    r.settingsScreen.controls.expectGamepadSlotsFound();

    expect(find.text('No gamepads detected'), findsOneWidget);
  });

  testWidgets('names each detected gamepad and its slot', (tester) async {
    final r = await openControlsTab(tester);

    r.container
        .read(gamepadSlotRegistryProvider)
        .observe('a', const GamepadDeviceKey(name: 'Sony DualSense'));

    await tester.pumpAndSettle();

    expect(find.text('Gamepad 1'), findsOneWidget);
    expect(find.text('Sony DualSense'), findsOneWidget);
  });

  testWidgets('lists two gamepads in slot order', (tester) async {
    final r = await openControlsTab(tester);

    final registry = r.container.read(gamepadSlotRegistryProvider)
      ..observe('a', const GamepadDeviceKey(name: 'Sony DualSense'))
      ..observe('b', const GamepadDeviceKey(name: '8BitDo Pro 2'));

    await tester.pumpAndSettle();

    expect(registry.assignments.map((a) => a.slot), [0, 1]);
    expect(find.text('Gamepad 2'), findsOneWidget);
    expect(find.text('8BitDo Pro 2'), findsOneWidget);
  });

  testWidgets('reassigning a gamepad swaps the two slots', (tester) async {
    final r = await openControlsTab(tester);

    final registry = r.container.read(gamepadSlotRegistryProvider)
      ..observe('a', const GamepadDeviceKey(name: 'Sony DualSense'))
      ..observe('b', const GamepadDeviceKey(name: '8BitDo Pro 2'));

    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Move to Gamepad 1'));
    await tester.pumpAndSettle();

    expect(registry.slotOf('b'), 0);
    expect(registry.slotOf('a'), 1);

    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Gamepad 1'),
          matching: find.byType(SettingsTile),
        ),
        matching: find.text('8BitDo Pro 2'),
      ),
      findsOneWidget,
      reason: 'the rows follow the registry',
    );
  });
}
