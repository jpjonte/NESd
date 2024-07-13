import 'package:nesd/ui/emulator/input/action.dart';
import 'package:nesd/ui/settings/controls/controls_settings.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'binder_state.g.dart';

@riverpod
class BinderState extends _$BinderState {
  @override
  ({bool editing, InputCombination? input}) build(NesAction action) {
    final profileIndex = ref.watch(profileIndexProvider);
    return (
      editing: false,
      input: ref.watch(
        settingsControllerProvider.select(
          (settings) =>
              settings.bindings[action]?.elementAtOrNull(profileIndex),
        ),
      )
    );
  }

  bool get editing => state.editing;

  set editing(bool value) {
    state = (editing: value, input: state.input);
  }

  InputCombination? get input => state.input;

  set input(InputCombination? value) {
    state = (editing: state.editing, input: value);
  }
}
