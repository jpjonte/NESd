import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gamepads/gamepads.dart';
import 'package:nes/extension/iterable_extension.dart';
import 'package:nes/ui/emulator/input/action.dart';
import 'package:nes/ui/settings/controls/binder_state.dart';
import 'package:nes/ui/settings/controls/controls_settings.dart';
import 'package:nes/ui/settings/controls/gamepad_input.dart';
import 'package:nes/ui/settings/controls/input_combination.dart';
import 'package:nes/ui/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'binder_controller.g.dart';

class BinderController {
  BinderController({
    required this.action,
    required this.profileIndex,
    required this.settingsController,
    required this.state,
    required this.inputs,
  }) {
    _subscription = Gamepads.events.listen(_handleGamepadEvent);
  }

  final NesAction action;
  final int profileIndex;
  final SettingsController settingsController;
  final BinderState state;
  final List<InputCombination?> inputs;

  late final StreamSubscription<GamepadEvent> _subscription;

  void onDispose() {
    _subscription.cancel();
  }

  void toggleEditing() {
    if (state.editing) {
      state.editing = false;
    } else {
      state
        ..editing = true
        ..input = null;
    }
  }

  void clearBinding() {
    state.editing = false;
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
      state.editing = false;

      settingsController.updateBinding(action, profileIndex, updatedBinding);
    }

    return KeyEventResult.ignored;
  }

  void _handleGamepadEvent(GamepadEvent event) {
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
      (input) => input.id == event.key,
    );

    if (event.value.abs() > 0.5) {
      state.input = updatedBinding.copyWith(
        inputs: {
          ...updatedBinding.inputs,
          GamepadInput(
            id: event.key,
            direction: event.value.sign.toInt(),
            label: event.label,
          ),
        },
      );
    } else if (gamepadInput != null) {
      state.editing = false;

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
  );

  ref.onDispose(controller.onDispose);

  return controller;
}
