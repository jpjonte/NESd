import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_event.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_mapper.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/settings/controls/binder_state.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/controls/controls_settings.dart';
import 'package:nesd/ui/settings/controls/gamepad_input.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'binder_controller.g.dart';

class BinderController {
  BinderController({
    required this.action,
    required this.profileIndex,
    required this.settingsController,
    required this.state,
    required this.stateNotifier,
    required this.actionHandler,
    required GamepadInputMapper gamepadInputMapper,
  }) {
    _subscription = gamepadInputMapper.stream.listen(_handleGamepadEvent);
  }

  final InputAction action;
  final int profileIndex;
  final SettingsController settingsController;
  final BinderState state;
  final BinderStateNotifier stateNotifier;
  final ActionHandler actionHandler;

  late final StreamSubscription<GamepadInputEvent> _subscription;

  void onDispose() {
    _subscription.cancel();
  }

  bool get editing => state.editing;

  set editing(bool value) {
    if (value == state.editing) {
      return;
    }

    if (value) {
      stateNotifier.input = null;

      actionHandler.enabled = false;
    } else {
      actionHandler.enabled = true;
    }

    stateNotifier.editing = value;
  }

  void clearBinding() {
    editing = false;
    settingsController.clearBinding(action, profileIndex);
  }

  KeyEventResult handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!state.editing) {
      return KeyEventResult.ignored;
    }

    if (event is KeyRepeatEvent) {
      return KeyEventResult.handled;
    }

    final updatedInput = state.input ?? const InputCombination.keyboard({});

    if (updatedInput is! KeyboardInputCombination) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent) {
      stateNotifier.input = updatedInput.copyWith(
        keys: {...updatedInput.keys, event.logicalKey},
      );

      return KeyEventResult.handled;
    }

    if (event is KeyUpEvent) {
      editing = false;

      final existingBinding =
          settingsController.getBinding(action, profileIndex) ??
          Binding(action: action, index: profileIndex, input: updatedInput);

      settingsController.updateBinding(
        existingBinding.copyWith(input: updatedInput),
      );
    }

    return KeyEventResult.ignored;
  }

  void _handleGamepadEvent(GamepadInputEvent event) {
    if (!state.editing) {
      return;
    }

    final updatedInput =
        state.input ??
        InputCombination.gamepad(
          gamepadId: event.gamepadId,
          gamepadName: event.gamepadName,
          inputs: const {},
        );

    if (updatedInput is! GamepadInputCombination) {
      return;
    }

    if (event.gamepadId != updatedInput.gamepadId) {
      return;
    }

    final gamepadInput = updatedInput.inputs.firstWhereOrNull(
      (input) => input.id == event.inputId,
    );

    if (event.value.abs() > 0.5) {
      stateNotifier.input = updatedInput.copyWith(
        inputs: {
          ...updatedInput.inputs,
          GamepadInput(
            id: event.inputId,
            direction: event.value.sign.toInt(),
            label: event.label,
          ),
        },
      );
    } else if (gamepadInput != null) {
      editing = false;

      final existingBinding =
          settingsController.getBinding(action, profileIndex) ??
          Binding(action: action, index: profileIndex, input: updatedInput);

      settingsController.updateBinding(
        existingBinding.copyWith(input: updatedInput),
      );
    }
  }
}

@riverpod
BinderController binderController(Ref ref, InputAction action) {
  final settingsController = ref.watch(settingsControllerProvider.notifier);

  final controller = BinderController(
    action: action,
    profileIndex: ref.watch(profileIndexProvider),
    settingsController: settingsController,
    state: ref.watch(binderStateNotifierProvider(action)),
    stateNotifier: ref.watch(binderStateNotifierProvider(action).notifier),
    actionHandler: ref.watch(actionHandlerProvider),
    gamepadInputMapper: ref.watch(gamepadInputMapperProvider),
  );

  ref.onDispose(controller.onDispose);

  return controller;
}
