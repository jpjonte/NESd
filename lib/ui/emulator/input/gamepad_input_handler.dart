import 'dart:async';

import 'package:gamepads/gamepads.dart';
import 'package:nes/ui/emulator/input/action.dart';
import 'package:nes/ui/emulator/input/action_handler.dart';
import 'package:nes/ui/settings/controls/gamepad_input.dart';
import 'package:nes/ui/settings/controls/input_combination.dart';
import 'package:nes/ui/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gamepad_input_handler.g.dart';

typedef PriorityAction = ({int priority, NesAction action});
typedef GamepadMap
    = Map<({String gamepadId, Set<GamepadInput> state}), NesAction>;

const _inputOnThreshold = 0.2;
const _inputOffThreshold = 0.1;

@riverpod
GamepadInputHandler gamepadInputHandler(GamepadInputHandlerRef ref) {
  final bindings = ref.watch(
    settingsControllerProvider.select((settings) => settings.bindings),
  );

  final actionStream = ref.watch(actionStreamProvider);

  final input = GamepadInputHandler(bindings, actionStream: actionStream);

  ref.onDispose(input.dispose);

  return input;
}

class GamepadInputHandler {
  GamepadInputHandler(BindingMap bindings, {required this.actionStream}) {
    _bindings = _buildBindingMap(bindings);
    _subscription = Gamepads.events.listen(_handleGamepadEvent);
  }

  final ActionStream actionStream;

  late final StreamSubscription<GamepadEvent> _subscription;

  final _state = <String, Set<GamepadInput>>{};

  late final GamepadMap _bindings;

  void dispose() {
    _subscription.cancel();
  }

  void _handleGamepadEvent(GamepadEvent event) {
    // get actions that match the previous state
    final previousActions = _getActions();

    _updateState(event);

    // get actions that match the current state
    final currentActions = _getActions();

    final value = event.value.abs();

    if (value > _inputOnThreshold) {
      // handle all actions that are new
      // until we reach an action with lower priority
      _addActions(
        value,
        currentActions,
        previousActions,
        highesPriorityOnly: true,
      );
    } else if (value < _inputOffThreshold) {
      // handle all actions that are no longer active
      _addActions(
        value,
        previousActions,
        currentActions,
      );
    }
  }

  // get actions that match the pressed keys, sorted by highest priority first
  // priority = number of actions
  List<PriorityAction> _getActions() {
    final actions = <PriorityAction>[];

    for (final MapEntry(key: input, value: action) in _bindings.entries) {
      final gamepadState = _state[input.gamepadId];

      if (gamepadState == null) {
        continue;
      }

      if (gamepadState.containsAll(input.state)) {
        actions.add((priority: input.state.length, action: action));
      }
    }

    actions.sort((a, b) => b.priority.compareTo(a.priority));

    return actions;
  }

  void _updateState(GamepadEvent event) {
    final initialState = _state[event.gamepadId] ?? {};
    final value = event.value.abs();

    if (value > _inputOnThreshold) {
      _state[event.gamepadId] = {
        ...initialState,
        GamepadInput(
          id: event.key,
          direction: event.value.sign.toInt(),
        ),
      };
    } else if (value < _inputOffThreshold) {
      _state[event.gamepadId] = {
        ...initialState,
      }..removeWhere((button) => button.id == event.key);
    }
  }

  void _addActions(
    double value,
    List<PriorityAction> baseActions,
    List<PriorityAction> compareActions, {
    bool highesPriorityOnly = false,
  }) {
    int? priority;

    for (final action in baseActions) {
      priority ??= action.priority;

      if (highesPriorityOnly && action.priority < priority) {
        break;
      }

      if (!compareActions.contains(action)) {
        actionStream.add((action: action.action, value: value));
      }
    }
  }

  GamepadMap _buildBindingMap(BindingMap bindings) {
    return {
      for (final MapEntry(key: action, value: inputs) in bindings.entries)
        for (final input in inputs)
          if (input case final GamepadInputCombination input)
            (gamepadId: input.gamepadId, state: input.inputs): action,
    };
  }
}
