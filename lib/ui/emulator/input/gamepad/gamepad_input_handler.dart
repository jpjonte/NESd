import 'dart:async';

import 'package:nes/ui/emulator/input/action.dart';
import 'package:nes/ui/emulator/input/action_handler.dart';
import 'package:nes/ui/emulator/input/gamepad/gamepad_input_event.dart';
import 'package:nes/ui/emulator/input/gamepad/gamepad_input_mapper.dart';
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
  final inputMapper = ref.watch(gamepadInputMapperProvider);

  final input = GamepadInputHandler(
    bindings,
    actionStream: actionStream,
    inputMapper: inputMapper,
  );

  ref.onDispose(input.dispose);

  return input;
}

class GamepadInputHandler {
  GamepadInputHandler(
    BindingMap bindings, {
    required this.actionStream,
    required GamepadInputMapper inputMapper,
  }) {
    _bindings = _buildBindingMap(bindings);
    _subscription = inputMapper.stream.listen(_handleGamepadEvent);
  }

  final ActionStream actionStream;

  late final StreamSubscription<GamepadInputEvent> _subscription;

  final _state = <String, Set<GamepadInput>>{};

  late final GamepadMap _bindings;

  void dispose() {
    _subscription.cancel();
  }

  void _handleGamepadEvent(GamepadInputEvent event) {
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

  void _updateState(GamepadInputEvent event) {
    final initialState = _state[event.gamepadId] ?? {};
    final value = event.value.abs();

    if (value > _inputOnThreshold) {
      _state[event.gamepadId] = {
        ...initialState,
        GamepadInput(
          id: event.inputId,
          direction: event.value.sign.toInt(),
        ),
      };
    } else if (value < _inputOffThreshold) {
      _state[event.gamepadId] = {
        ...initialState,
      }..removeWhere((button) => button.id == event.inputId);
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
