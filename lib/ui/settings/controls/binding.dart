import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nes/ui/emulator/input/action.dart';
import 'package:nes/ui/emulator/input/action/controller_press.dart';
import 'package:nes/ui/emulator/input/action/load_file.dart';
import 'package:nes/ui/emulator/input/action/save_state.dart';
import 'package:nes/ui/settings/controls/gamepad_input.dart';

part 'binding.freezed.dart';
part 'binding.g.dart';

final defaultBindings = {
  controller1Up: InputCombination.keyboard({LogicalKeyboardKey.arrowUp}),
  controller1Down: InputCombination.keyboard({LogicalKeyboardKey.arrowDown}),
  controller1Left: InputCombination.keyboard({LogicalKeyboardKey.arrowLeft}),
  controller1Right: InputCombination.keyboard({LogicalKeyboardKey.arrowRight}),
  controller1Start: InputCombination.keyboard({LogicalKeyboardKey.enter}),
  controller1Select: InputCombination.keyboard({LogicalKeyboardKey.shift}),
  controller1A: InputCombination.keyboard({LogicalKeyboardKey.keyZ}),
  controller1B: InputCombination.keyboard({LogicalKeyboardKey.keyX}),
  loadState1: InputCombination.keyboard({LogicalKeyboardKey.digit1}),
  saveState1: InputCombination.keyboard(
    {LogicalKeyboardKey.digit1, LogicalKeyboardKey.shift},
  ),
  loadState2: InputCombination.keyboard({LogicalKeyboardKey.digit2}),
  saveState2: InputCombination.keyboard(
    {LogicalKeyboardKey.digit2, LogicalKeyboardKey.shift},
  ),
  loadState3: InputCombination.keyboard({LogicalKeyboardKey.digit3}),
  saveState3: InputCombination.keyboard(
    {LogicalKeyboardKey.digit3, LogicalKeyboardKey.shift},
  ),
  loadState4: InputCombination.keyboard({LogicalKeyboardKey.digit4}),
  saveState4: InputCombination.keyboard(
    {LogicalKeyboardKey.digit4, LogicalKeyboardKey.shift},
  ),
  loadState5: InputCombination.keyboard({LogicalKeyboardKey.digit5}),
  saveState5: InputCombination.keyboard(
    {LogicalKeyboardKey.digit5, LogicalKeyboardKey.shift},
  ),
  loadState6: InputCombination.keyboard({LogicalKeyboardKey.digit6}),
  saveState6: InputCombination.keyboard(
    {LogicalKeyboardKey.digit6, LogicalKeyboardKey.shift},
  ),
  loadState7: InputCombination.keyboard({LogicalKeyboardKey.digit7}),
  saveState7: InputCombination.keyboard(
    {LogicalKeyboardKey.digit7, LogicalKeyboardKey.shift},
  ),
  loadState8: InputCombination.keyboard({LogicalKeyboardKey.digit8}),
  saveState8: InputCombination.keyboard(
    {LogicalKeyboardKey.digit8, LogicalKeyboardKey.shift},
  ),
  loadState9: InputCombination.keyboard({LogicalKeyboardKey.digit9}),
  saveState9: InputCombination.keyboard(
    {LogicalKeyboardKey.digit9, LogicalKeyboardKey.shift},
  ),
};

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

NesAction actionFromJson(String json) {
  return allActions.firstWhere((action) => action.code == json);
}

String actionToJson(NesAction action) {
  return action.code;
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

    return sorted.map((key) => key.keyLabel).join(' + ');
  }

  static String _gamepadLabel(GamepadInputCombination input) {
    final buttons = input.inputs.map((button) => button.label ?? button.id);

    return '${input.gamepadName} (${input.gamepadId})\n'
        '${buttons.join(' + ')}';
  }

  factory InputCombination.fromJson(Map<String, dynamic> json) =>
      _$InputCombinationFromJson(json);
}
