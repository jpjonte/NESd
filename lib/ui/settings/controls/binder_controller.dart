import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nesd/extension/iterable_extension.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_event.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_mapper.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/settings/controls/binder_state.dart';
import 'package:nesd/ui/settings/controls/controls_settings.dart';
import 'package:nesd/ui/settings/controls/gamepad_input.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'binder_controller.g.dart';

class BinderController {
  BinderController({
    required this.action,
    required this.profileIndex,
    required this.settingsController,
    required this.state,
    required this.inputs,
    required this.actionHandler,
    required GamepadInputMapper gamepadInputMapper,
  }) {
    _subscription = gamepadInputMapper.stream.listen(_handleGamepadEvent);
  }

  final InputAction action;
  final int profileIndex;
  final SettingsController settingsController;
  final BinderState state;
  final List<InputCombination?> inputs;
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
      state.input = null;

      actionHandler.enabled = false;
    } else {
      actionHandler.enabled = true;
    }

    state.editing = value;
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

    final updatedBinding = state.input ?? const InputCombination.keyboard({});

    if (updatedBinding is! KeyboardInputCombination) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent) {
      state.input = updatedBinding.copyWith(
        keys: {
          ...updatedBinding.keys,
          event.logicalKey,
        },
      );

      return KeyEventResult.handled;
    }

    if (event is KeyUpEvent) {
      editing = false;

      settingsController.updateBinding(action, profileIndex, updatedBinding);
    }

    return KeyEventResult.ignored;
  }

  void _handleGamepadEvent(GamepadInputEvent event) {
    if (!state.editing) {
      return;
    }

    final updatedBinding = state.input ??
        InputCombination.gamepad(
          gamepadId: event.gamepadId,
          gamepadName: event.gamepadName,
          inputs: const {},
        );

    if (updatedBinding is! GamepadInputCombination) {
      return;
    }

    if (event.gamepadId != updatedBinding.gamepadId) {
      return;
    }

    final gamepadInput = updatedBinding.inputs.firstWhereOrNull(
      (input) => input.id == event.inputId,
    );

    if (event.value.abs() > 0.5) {
      state.input = updatedBinding.copyWith(
        inputs: {
          ...updatedBinding.inputs,
          GamepadInput(
            id: event.inputId,
            direction: event.value.sign.toInt(),
            label: event.label,
          ),
        },
      );
    } else if (gamepadInput != null) {
      editing = false;

      settingsController.updateBinding(action, profileIndex, updatedBinding);
    }
  }
}

@riverpod
BinderController binderController(BinderControllerRef ref, NesAction action) {
  final controller = BinderController(
    action: action,
    profileIndex: ref.watch(profileIndexProvider),
    settingsController: ref.watch(settingsControllerProvider.notifier),
    state: ref.watch(binderStateProvider(action).notifier),
    inputs: ref.watch(
      settingsControllerProvider
          .select((settings) => settings.bindings[action] ?? []),
    ),
    actionHandler: ref.watch(actionHandlerProvider),
    gamepadInputMapper: ref.watch(gamepadInputMapperProvider),
  );

  ref.onDispose(controller.onDispose);

  return controller;
}
