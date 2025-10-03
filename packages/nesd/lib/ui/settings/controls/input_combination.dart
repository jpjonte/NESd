import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/controls/gamepad_input.dart';

part 'input_combination.freezed.dart';
part 'input_combination.g.dart';

final defaultBindings = [
  Binding(
    index: 0,
    action: controller1Up,
    input: InputCombination.keyboard({LogicalKeyboardKey.arrowUp}),
  ),
  Binding(
    index: 0,
    action: controller1Down,
    input: InputCombination.keyboard({LogicalKeyboardKey.arrowDown}),
  ),
  Binding(
    index: 0,
    action: controller1Left,
    input: InputCombination.keyboard({LogicalKeyboardKey.arrowLeft}),
  ),
  Binding(
    index: 0,
    action: controller1Right,
    input: InputCombination.keyboard({LogicalKeyboardKey.arrowRight}),
  ),
  Binding(
    index: 0,
    action: controller1Start,
    input: InputCombination.keyboard({LogicalKeyboardKey.enter}),
  ),
  Binding(
    index: 0,
    action: controller1Select,
    input: InputCombination.keyboard({LogicalKeyboardKey.shift}),
  ),
  Binding(
    index: 0,
    action: controller1A,
    input: InputCombination.keyboard({LogicalKeyboardKey.keyZ}),
  ),
  Binding(
    index: 0,
    action: controller1B,
    input: InputCombination.keyboard({LogicalKeyboardKey.keyX}),
  ),
  Binding(
    index: 0,
    action: loadState0,
    input: InputCombination.keyboard({LogicalKeyboardKey.digit0}),
  ),
  Binding(
    index: 0,
    action: loadState1,
    input: InputCombination.keyboard({LogicalKeyboardKey.digit1}),
  ),
  Binding(
    index: 0,
    action: saveState1,
    input: InputCombination.keyboard({
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.shift,
    }),
  ),
  Binding(
    index: 0,
    action: loadState2,
    input: InputCombination.keyboard({LogicalKeyboardKey.digit2}),
  ),
  Binding(
    index: 0,
    action: saveState2,
    input: InputCombination.keyboard({
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.shift,
    }),
  ),
  Binding(
    index: 0,
    action: loadState3,
    input: InputCombination.keyboard({LogicalKeyboardKey.digit3}),
  ),
  Binding(
    index: 0,
    action: saveState3,
    input: InputCombination.keyboard({
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.shift,
    }),
  ),
  Binding(
    index: 0,
    action: loadState4,
    input: InputCombination.keyboard({LogicalKeyboardKey.digit4}),
  ),
  Binding(
    index: 0,
    action: saveState4,
    input: InputCombination.keyboard({
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.shift,
    }),
  ),
  Binding(
    index: 0,
    action: loadState5,
    input: InputCombination.keyboard({LogicalKeyboardKey.digit5}),
  ),
  Binding(
    index: 0,
    action: saveState5,
    input: InputCombination.keyboard({
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.shift,
    }),
  ),
  Binding(
    index: 0,
    action: loadState6,
    input: InputCombination.keyboard({LogicalKeyboardKey.digit6}),
  ),
  Binding(
    index: 0,
    action: saveState6,
    input: InputCombination.keyboard({
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.shift,
    }),
  ),
  Binding(
    index: 0,
    action: loadState7,
    input: InputCombination.keyboard({LogicalKeyboardKey.digit7}),
  ),
  Binding(
    index: 0,
    action: saveState7,
    input: InputCombination.keyboard({
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.shift,
    }),
  ),
  Binding(
    index: 0,
    action: loadState8,
    input: InputCombination.keyboard({LogicalKeyboardKey.digit8}),
  ),
  Binding(
    index: 0,
    action: saveState8,
    input: InputCombination.keyboard({
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.shift,
    }),
  ),
  Binding(
    index: 0,
    action: loadState9,
    input: InputCombination.keyboard({LogicalKeyboardKey.digit9}),
  ),
  Binding(
    index: 0,
    action: saveState9,
    input: InputCombination.keyboard({
      LogicalKeyboardKey.digit9,
      LogicalKeyboardKey.shift,
    }),
  ),
  Binding(
    index: 0,
    action: pause,
    input: InputCombination.keyboard({LogicalKeyboardKey.space}),
    type: BindingType.toggle,
  ),
  Binding(
    index: 0,
    action: fastForward,
    input: InputCombination.keyboard({LogicalKeyboardKey.tab}),
  ),
  Binding(
    index: 0,
    action: rewind,
    input: InputCombination.keyboard({LogicalKeyboardKey.backspace}),
  ),
  Binding(
    index: 0,
    action: openMenu,
    input: InputCombination.keyboard({LogicalKeyboardKey.escape}),
  ),
  Binding(
    index: 0,
    action: previousInput,
    input: InputCombination.keyboard({LogicalKeyboardKey.arrowUp}),
  ),
  Binding(
    index: 0,
    action: nextInput,
    input: InputCombination.keyboard({LogicalKeyboardKey.arrowDown}),
  ),
  Binding(
    index: 0,
    action: confirm,
    input: InputCombination.keyboard({LogicalKeyboardKey.enter}),
  ),
  Binding(
    index: 0,
    action: secondaryAction,
    input: InputCombination.keyboard({LogicalKeyboardKey.shift}),
  ),
  Binding(
    index: 0,
    action: cancel,
    input: InputCombination.keyboard({LogicalKeyboardKey.backspace}),
  ),
  Binding(
    index: 0,
    action: previousTab,
    input: InputCombination.keyboard({
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.tab,
    }),
  ),
  Binding(
    index: 0,
    action: nextTab,
    input: InputCombination.keyboard({LogicalKeyboardKey.tab}),
  ),
];

Set<LogicalKeyboardKey> keysFromJson(List<dynamic> json) {
  final keys = json.cast<int>();

  return keys
      .map((keyId) => LogicalKeyboardKey.findKeyByKeyId(keyId))
      .where((k) => k != null)
      .cast<LogicalKeyboardKey>()
      .toSet();
}

List<int> keysToJson(Set<LogicalKeyboardKey> keys) {
  return keys.map((key) => key.keyId).toList();
}

@Freezed(unionKey: 'type', fallbackUnion: 'keyboard')
sealed class InputCombination with _$InputCombination {
  const InputCombination._();

  const factory InputCombination.keyboard(
    @JsonKey(fromJson: keysFromJson, toJson: keysToJson)
    Set<LogicalKeyboardKey> keys,
  ) = KeyboardInputCombination;

  const factory InputCombination.gamepad({
    required String gamepadId,
    required Set<GamepadInput> inputs,
    @Default('Unknown') String gamepadName,
  }) = GamepadInputCombination;

  String get label => switch (this) {
    final KeyboardInputCombination input => _keyboardLabel(input),
    final GamepadInputCombination input => _gamepadLabel(input),
  };

  static String _keyboardLabel(KeyboardInputCombination input) {
    final sorted = input.keys.toList()..sort((a, b) => b.keyId - a.keyId);

    return sorted
        .map((key) => key.keyLabel == ' ' ? 'Space' : key.keyLabel)
        .join(' + ');
  }

  static String _gamepadLabel(GamepadInputCombination input) {
    final buttons = input.inputs.map((button) => button.label ?? button.id);

    return '${input.gamepadName} (${input.gamepadId})\n'
        '${buttons.join(' + ')}';
  }

  factory InputCombination.fromJson(Map<String, dynamic> json) =>
      _$InputCombinationFromJson(json);
}
