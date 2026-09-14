import 'package:flutter/foundation.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_handler.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/input/input_method.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'input_hint_resolver.g.dart';

@immutable
class InputHintResolver {
  const InputHintResolver({
    required this.method,
    required this.bindings,
    this.gamepadSlot = 0,
  });

  final InputMethod method;
  final Bindings bindings;
  final int gamepadSlot;

  InputCombination? bindingFor(InputAction action) {
    Binding? best;

    for (final binding in bindings) {
      if (binding.action != action || !_matches(binding.input)) {
        continue;
      }

      if (best == null || binding.index < best.index) {
        best = binding;
      }
    }

    return best?.input;
  }

  bool _matches(InputCombination input) => switch ((method, input)) {
    (InputMethod.keyboardMouse, KeyboardInputCombination()) => true,
    (InputMethod.gamepad, GamepadInputCombination(:final slot)) =>
      slot == gamepadSlot,
    _ => false,
  };
}

@riverpod
InputHintResolver inputHintResolver(Ref ref) {
  final recent = ref.watch(recentInputMethodProvider);
  final bindings = ref.watch(
    settingsControllerProvider.select((settings) => settings.bindings),
  );
  final registry = ref.watch(gamepadSlotRegistryProvider);

  void refresh() => ref.invalidateSelf();

  registry.addListener(refresh);

  ref.onDispose(() => registry.removeListener(refresh));

  final gamepadId = recent.gamepadId;

  return InputHintResolver(
    method: recent.method,
    bindings: bindings,
    gamepadSlot: gamepadId == null ? 0 : registry.slotOf(gamepadId) ?? 0,
  );
}
