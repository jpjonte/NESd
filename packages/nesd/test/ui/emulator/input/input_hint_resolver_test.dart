import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_directory.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_key.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_handler.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_id.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_slot_registry.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/input/input_hint_resolver.dart';
import 'package:nesd/ui/emulator/input/input_method.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

Binding _keyboard(
  InputAction action,
  Set<LogicalKeyboardKey> keys, {
  int index = 0,
}) => Binding(
  index: index,
  action: action,
  input: InputCombination.keyboard(keys),
);

Binding _gamepad(
  InputAction action,
  GamepadButton button, {
  int slot = 0,
  int index = 1,
}) => Binding(
  index: index,
  action: action,
  input: InputCombination.gamepad(
    slot: slot,
    inputs: {gamepadButtonInput(button)},
  ),
);

final _bindings = [
  _keyboard(confirm, {LogicalKeyboardKey.space}, index: 3),
  _keyboard(confirm, {LogicalKeyboardKey.enter}),
  _gamepad(confirm, GamepadButton.a),
  _gamepad(confirm, GamepadButton.b, slot: 1),
  _keyboard(cancel, {LogicalKeyboardKey.escape}),
  _gamepad(openMenu, GamepadButton.start),
];

class _FixedRecentInput extends RecentInputMethod {
  _FixedRecentInput(this.value);

  final RecentInput value;

  @override
  RecentInput build() => value;
}

void main() {
  group('bindingFor', () {
    test('keyboard picks the keyboard binding with the lowest index', () {
      final resolver = InputHintResolver(
        method: InputMethod.keyboardMouse,
        bindings: _bindings,
      );

      expect(
        resolver.bindingFor(confirm),
        InputCombination.keyboard({LogicalKeyboardKey.enter}),
      );
    });

    test('keyboard ignores actions bound only on a gamepad', () {
      final resolver = InputHintResolver(
        method: InputMethod.keyboardMouse,
        bindings: _bindings,
      );

      expect(resolver.bindingFor(openMenu), isNull);
    });

    test('gamepad picks the binding on the slot of the gamepad used last', () {
      final slot0 = InputHintResolver(
        method: InputMethod.gamepad,
        bindings: _bindings,
      );
      final slot1 = InputHintResolver(
        method: InputMethod.gamepad,
        bindings: _bindings,
        gamepadSlot: 1,
      );

      expect(
        slot0.bindingFor(confirm),
        InputCombination.gamepad(
          slot: 0,
          inputs: {gamepadButtonInput(GamepadButton.a)},
        ),
      );
      expect(
        slot1.bindingFor(confirm),
        InputCombination.gamepad(
          slot: 1,
          inputs: {gamepadButtonInput(GamepadButton.b)},
        ),
      );
    });

    test('gamepad has nothing for an action unbound on that slot', () {
      final resolver = InputHintResolver(
        method: InputMethod.gamepad,
        bindings: _bindings,
        gamepadSlot: 1,
      );

      expect(resolver.bindingFor(cancel), isNull);
    });

    test('touch has no prompt', () {
      final resolver = InputHintResolver(
        method: InputMethod.touch,
        bindings: _bindings,
      );

      expect(resolver.bindingFor(confirm), isNull);
    });

    test('an unbound action has no prompt', () {
      final resolver = InputHintResolver(
        method: InputMethod.keyboardMouse,
        bindings: _bindings,
      );

      expect(resolver.bindingFor(nextTab), isNull);
    });
  });

  group('inputHintResolverProvider', () {
    const pad1 = GamepadDeviceKey(name: 'Pad 1', vendorId: 1, productId: 1);
    const pad2 = GamepadDeviceKey(name: 'Pad 2', vendorId: 1, productId: 2);

    late GamepadSlotRegistry registry;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});

      final prefs = await SharedPreferences.getInstance();

      registry = GamepadSlotRegistry(
        directory: GamepadDeviceDirectory(
          lookup: () async => {'pad-1': pad1, 'pad-2': pad2},
        ),
      );

      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          gamepadSlotRegistryProvider.overrideWith((_) => registry),
          recentInputMethodProvider.overrideWith(
            () => _FixedRecentInput(
              const RecentInput(
                method: InputMethod.gamepad,
                gamepadId: 'pad-2',
              ),
            ),
          ),
        ],
      );

      addTearDown(container.dispose);
    });

    InputHintResolver resolver() => container.read(inputHintResolverProvider);

    test('reads the method and the settings bindings', () {
      expect(resolver().method, InputMethod.gamepad);
      expect(
        resolver().bindings,
        container.read(settingsControllerProvider).bindings,
      );
    });

    test('uses the slot of the gamepad used last', () {
      registry
        ..observe('pad-1', pad1)
        ..observe('pad-2', pad2);

      expect(resolver().gamepadSlot, 1);
    });

    test('follows slot reassignments', () {
      registry
        ..observe('pad-1', pad1)
        ..observe('pad-2', pad2);

      expect(resolver().gamepadSlot, 1);

      registry.assign(0, 'pad-2');

      expect(resolver().gamepadSlot, 0);
    });

    test('falls back to slot 0 for a gamepad without a slot', () {
      expect(resolver().gamepadSlot, 0);
    });
  });
}
