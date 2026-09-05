import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/action/all_actions.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';

void main() {
  test('the rewind timeline action is registered', () {
    expect(allActions.whereType<RewindTimelineAction>(), hasLength(1));
    expect(rewindTimeline.code, 'state.rewindTimeline');
  });

  test('defaults to shift + backspace', () {
    final binding = defaultBindings.firstWhere(
      (b) => b.action == rewindTimeline,
    );

    expect(
      binding.input,
      InputCombination.keyboard({
        LogicalKeyboardKey.shift,
        LogicalKeyboardKey.backspace,
      }),
    );
  });

  test('does not collide with the plain rewind binding', () {
    final rewindBinding = defaultBindings.firstWhere((b) => b.action == rewind);
    final timelineBinding = defaultBindings.firstWhere(
      (b) => b.action == rewindTimeline,
    );

    expect(rewindBinding.input, isNot(timelineBinding.input));
  });
}
