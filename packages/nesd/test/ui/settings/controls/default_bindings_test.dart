import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/action/all_actions.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';

void main() {
  test('no action is bound twice in the same profile', () {
    final seen = <(InputAction, int)>{};

    for (final binding in defaultBindings) {
      expect(
        seen.add((binding.action, binding.index)),
        isTrue,
        reason: '${binding.action.code} is bound twice at ${binding.index}',
      );
    }
  });

  test('every default action is a known action', () {
    for (final binding in defaultBindings) {
      expect(allActions, contains(binding.action));
    }
  });

  test('gamepad defaults cover both controllers', () {
    final gamepad = defaultBindings
        .where((b) => b.input is GamepadInputCombination)
        .toList();

    final slots = gamepad
        .map((b) => (b.input as GamepadInputCombination).slot)
        .toSet();

    expect(slots, {0, 1});

    for (final action in [
      controller1Up,
      controller1Down,
      controller1Left,
      controller1Right,
      controller1A,
      controller1B,
      controller1Start,
      controller1Select,
      controller2A,
      controller2B,
    ]) {
      expect(
        gamepad.any((b) => b.action == action),
        isTrue,
        reason: '${action.code} has no gamepad default',
      );
    }
  });

  test('menu navigation is reachable from a gamepad', () {
    final gamepad = defaultBindings
        .where((b) => b.input is GamepadInputCombination)
        .toList();

    for (final action in [
      openMenu,
      confirm,
      cancel,
      previousInput,
      nextInput,
    ]) {
      final binding = gamepad.firstWhere(
        (b) => b.action == action,
        orElse: () => throw StateError('${action.code} has no gamepad default'),
      );

      expect((binding.input as GamepadInputCombination).slot, 0);
    }
  });

  test('keyboard defaults are untouched at profile 1', () {
    final keyboard = defaultBindings
        .where((b) => b.input is KeyboardInputCombination)
        .toList();

    expect(keyboard.every((b) => b.index == 0), isTrue);
  });
}
