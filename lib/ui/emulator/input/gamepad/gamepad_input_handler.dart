import 'dart:async';

import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/bound_action.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_event.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_mapper.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/controls/gamepad_input.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gamepad_input_handler.g.dart';

typedef GamepadMap =
    Map<({String gamepadId, Set<GamepadInput> state}), Binding>;

const _inputOnThreshold = 0.2;
const _inputOffThreshold = 0.1;

@riverpod
GamepadInputHandler gamepadInputHandler(Ref ref) {
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
    Bindings bindings, {
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

  Timer? _delayTimer;
  Timer? _repeatTimer;

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

      _startRepeatDelay();
    } else if (value < _inputOffThreshold) {
      // handle all actions that are no longer active
      _addActions(value, previousActions, currentActions);
    }

    if (currentActions.isEmpty) {
      _stopRepeat();
    }
  }

  // get actions that match the pressed keys, sorted by highest priority first
  // priority = number of actions
  List<BoundAction> _getActions() {
    final actions = <BoundAction>[];

    for (final MapEntry(key: input, value: binding) in _bindings.entries) {
      final gamepadState = _state[input.gamepadId];

      if (gamepadState == null) {
        continue;
      }

      if (gamepadState.containsAll(input.state)) {
        actions.add(
          BoundAction(
            priority: input.state.length,
            action: binding.action,
            bindingType: binding.type,
          ),
        );
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
        GamepadInput(id: event.inputId, direction: event.value.sign.toInt()),
      };
    } else if (value < _inputOffThreshold) {
      _state[event.gamepadId] = {...initialState}
        ..removeWhere((button) => button.id == event.inputId);
    }
  }

  void _addActions(
    double value,
    List<BoundAction> baseActions,
    List<BoundAction> compareActions, {
    bool highesPriorityOnly = false,
  }) {
    int? priority;

    for (final action in baseActions) {
      priority ??= action.priority;

      if (highesPriorityOnly && action.priority < priority) {
        break;
      }

      if (!compareActions.contains(action)) {
        actionStream.add(
          InputActionEvent(
            action: action.action,
            value: value,
            bindingType: action.bindingType,
          ),
        );
      }
    }
  }

  GamepadMap _buildBindingMap(Bindings bindings) {
    final bindingMap =
        <({String gamepadId, Set<GamepadInput> state}), Binding>{};

    for (final binding in bindings) {
      if (binding.input case final GamepadInputCombination gamepadInput) {
        bindingMap[(
              gamepadId: gamepadInput.gamepadId,
              state: gamepadInput.inputs,
            )] =
            binding;
      }
    }

    return bindingMap;
  }

  void _startRepeatDelay() {
    _repeatTimer?.cancel();
    _delayTimer?.cancel();

    if (_state.entries.any((e) => e.value.isNotEmpty)) {
      _delayTimer = Timer(const Duration(milliseconds: 500), _startRepeat);
    }
  }

  void _startRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final actions = _getActions();

      if (actions.isEmpty) {
        _repeatTimer?.cancel();

        return;
      }

      for (final action in actions) {
        actionStream.add(
          InputActionEvent(
            action: action.action,
            value: 1.0,
            bindingType: action.bindingType,
          ),
        );
      }
    });
  }

  void _stopRepeat() {
    _delayTimer?.cancel();
    _repeatTimer?.cancel();
  }
}
