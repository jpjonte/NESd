import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/settings/controls/controls_settings.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'binder_state.freezed.dart';
part 'binder_state.g.dart';

@freezed
sealed class BinderState with _$BinderState {
  const factory BinderState({
    @Default(false) bool editing,
    InputCombination? input,
  }) = _BinderState;
}

@riverpod
class BinderStateNotifier extends _$BinderStateNotifier {
  @override
  BinderState build(InputAction action) {
    final profileIndex = ref.watch(profileIndexProvider);

    return BinderState(
      input: ref.watch(
        settingsControllerProvider.select(
          (settings) =>
              settings.bindings
                  .firstWhereOrNull(
                    (binding) =>
                        binding.action == action &&
                        binding.index == profileIndex,
                  )
                  ?.input,
        ),
      ),
    );
  }

  bool get editing => state.editing;

  set editing(bool value) {
    state = state.copyWith(editing: value);
  }

  InputCombination? get input => state.input;

  set input(InputCombination? value) {
    state = state.copyWith(input: value);
  }
}
