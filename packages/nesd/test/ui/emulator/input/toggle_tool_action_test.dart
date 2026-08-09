import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/action/all_actions.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/emulator/tools/emulator_tools_controller.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';

import '../../robot.dart';

void main() {
  test('every tool has a bindable action resolvable by code', () {
    for (final tool in EmulatorTool.values) {
      final action = InputAction.fromCode('tool.${tool.name}');

      expect(action, isA<ToggleTool>(), reason: 'missing action for $tool');
      expect((action! as ToggleTool).tool, tool);
      expect(allActions, contains(action));
    }
  });

  test('a tool binding survives a persistence round trip', () {
    final binding = Binding(
      index: 0,
      action: toggleDebugger,
      input: InputCombination.keyboard({LogicalKeyboardKey.f1}),
    );

    final restored = bindingsFromJson([binding.toJson()]);

    expect(restored, hasLength(1));
    expect(restored.single.action, same(toggleDebugger));
    expect(restored.single.input, binding.input);
  });

  testWidgets('a tool binding works in game and with the menu open', (
    tester,
  ) async {
    final r = Robot(tester)
      ..initSettings({
        'recentRoms': [
          {
            'file': {
              'path': '/test/roms/nestest.nes',
              'name': '/test/roms/nestest.nes',
              'type': 'file',
            },
          },
        ],
      });

    await r.pumpApp();
    await r.mainMenu.tapFirstRomTile();

    void press(InputAction action) {
      r.container.read(actionStreamProvider)
        ..add(
          InputActionEvent(
            action: action,
            value: 1.0,
            bindingType: BindingType.hold,
          ),
        )
        ..add(
          InputActionEvent(
            action: action,
            value: 0.0,
            bindingType: BindingType.hold,
          ),
        );
    }

    press(toggleDebugger);
    await tester.pump();

    expect(r.container.read(emulatorToolsControllerProvider), {
      EmulatorTool.debugger,
    });

    await r.emulator.tapMenu();
    r.menuScreen.expectMenuScreenFound();

    press(toggleDebugger);
    await tester.pump();

    expect(r.container.read(emulatorToolsControllerProvider), isEmpty);

    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });

  testWidgets('a held tool binding toggles only once until released', (
    tester,
  ) async {
    final r = Robot(tester)
      ..initSettings({
        'recentRoms': [
          {
            'file': {
              'path': '/test/roms/nestest.nes',
              'name': '/test/roms/nestest.nes',
              'type': 'file',
            },
          },
        ],
      });

    await r.pumpApp();
    await r.mainMenu.tapFirstRomTile();

    void send(double value) {
      r.container
          .read(actionStreamProvider)
          .add(
            InputActionEvent(
              action: toggleDebugger,
              value: value,
              bindingType: BindingType.hold,
            ),
          );
    }

    send(1.0);
    await tester.pump();

    // Hold-to-repeat re-emits the held action; it must not toggle again.
    send(1.0);
    await tester.pump();

    expect(r.container.read(emulatorToolsControllerProvider), {
      EmulatorTool.debugger,
    });

    // Releasing and pressing again is a new edge and toggles again.
    send(0.0);
    send(1.0);
    await tester.pump();

    expect(r.container.read(emulatorToolsControllerProvider), isEmpty);

    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);

    // Drain the worker's shutdown timer scheduled in the final cycle.
    await r.fixAsync();
  });
}
