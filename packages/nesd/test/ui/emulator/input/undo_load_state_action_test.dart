import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/action/all_actions.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';

void main() {
  test('the undo load state action is registered and bindable', () {
    expect(allActions.whereType<UndoLoadState>(), hasLength(1));
    expect(saveStateActions, contains(undoLoadState));
    expect(InputAction.fromCode('loadState.undo'), same(undoLoadState));
  });

  test('is an in-game action', () {
    expect(isInGameAction(undoLoadState), isTrue);
  });

  test('has no default binding', () {
    expect(
      defaultBindings.where((binding) => binding.action == undoLoadState),
      isEmpty,
    );
  });
}
