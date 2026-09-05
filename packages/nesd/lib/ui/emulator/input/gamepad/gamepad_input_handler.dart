import 'dart:async';

import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/bound_action.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_directory.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_event.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_mapper.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_slot_registry.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/controls/gamepad_input.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gamepad_input_handler.g.dart';

typedef GamepadBindings =
    List<({int slot, Set<GamepadInput> state, Binding binding})>;

const _inputOnThreshold = 0.2;
const _inputOffThreshold = 0.1;

const _repeatDelay = Duration(milliseconds: 500);
const _initialRepeatInterval = Duration(milliseconds: 100);
const _minRepeatInterval = Duration(milliseconds: 33);
const _repeatAcceleration = 0.9;

@riverpod
GamepadSlotRegistry gamepadSlotRegistry(Ref ref) {
  final settingsController = ref.read(settingsControllerProvider.notifier);

  final registry = GamepadSlotRegistry(
    remembered: settingsController.gamepadSlots,
    directory: ref.watch(gamepadDeviceDirectoryProvider),
  );

  void persist() => settingsController.gamepadSlots = registry.remembered;

  registry.addListener(persist);

  ref.onDispose(() {
    registry
      ..removeListener(persist)
      ..dispose();
  });

  unawaited(registry.seed());

  return registry;
}

@riverpod
GamepadInputHandler gamepadInputHandler(Ref ref) {
  final bindings = ref.watch(
    settingsControllerProvider.select((settings) => settings.bindings),
  );

  final actionStream = ref.watch(actionStreamProvider);
  final inputMapper = ref.watch(gamepadInputMapperProvider);
  final slotRegistry = ref.watch(gamepadSlotRegistryProvider);

  final input = GamepadInputHandler(
    bindings,
    actionStream: actionStream,
    inputMapper: inputMapper,
    slotRegistry: slotRegistry,
  );

  ref.onDispose(input.dispose);

  return input;
}

class GamepadInputHandler {
  GamepadInputHandler(
    Bindings bindings, {
    required this.actionStream,
    required GamepadInputMapper inputMapper,
    required this.slotRegistry,
  }) {
    _bindings = _buildBindings(bindings);
    _slots = _slotSnapshot();
    _subscription = inputMapper.stream.listen(_handleGamepadEvent);

    slotRegistry.addListener(_handleRegistryChange);
  }

  final ActionStream actionStream;
  final GamepadSlotRegistry slotRegistry;

  late final StreamSubscription<GamepadInputEvent> _subscription;

  final _state = <String, Set<GamepadInput>>{};

  late Map<int, String> _slots;

  late final GamepadBindings _bindings;

  Timer? _delayTimer;
  Timer? _repeatTimer;

  void dispose() {
    _subscription.cancel();
    slotRegistry.removeListener(_handleRegistryChange);
    _stopRepeat();
  }

  void _handleRegistryChange() {
    final slots = _slotSnapshot();
    final connected = slots.values.toSet();
    final released = _state.keys.where((id) => !connected.contains(id)).toSet();

    if (released.isNotEmpty) {
      final previousActions = _getActions((slot) => _slots[slot]);

      _state.removeWhere((id, _) => released.contains(id));

      _addActions(0, previousActions, _getActions((slot) => _slots[slot]));
    }

    _slots = slots;
  }

  Map<int, String> _slotSnapshot() => {
    for (final assignment in slotRegistry.assignments)
      assignment.slot: assignment.gamepadId,
  };

  void _handleGamepadEvent(GamepadInputEvent event) {
    // get actions that match the previous state
    final previousActions = _getActions(slotRegistry.gamepadIdFor);

    _updateState(event);

    // get actions that match the current state
    final currentActions = _getActions(slotRegistry.gamepadIdFor);

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
  List<BoundAction> _getActions(String? Function(int slot) gamepadIdFor) {
    final actions = <BoundAction>[];

    for (final (:slot, :state, :binding) in _bindings) {
      final gamepadId = gamepadIdFor(slot);

      if (gamepadId == null) {
        continue;
      }

      final gamepadState = _state[gamepadId];

      if (gamepadState == null) {
        continue;
      }

      if (gamepadState.containsAll(state)) {
        actions.add(
          BoundAction(
            priority: state.length,
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
    slotRegistry.observe(event.gamepadId, event.deviceKey);

    final initialState = _state[event.gamepadId] ?? {};
    final value = event.value.abs();

    if (value > _inputOnThreshold) {
      _state[event.gamepadId] = {...initialState}
        ..removeWhere((button) => button.id == event.inputId)
        ..add(
          GamepadInput(id: event.inputId, direction: event.value.sign.toInt()),
        );
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

  GamepadBindings _buildBindings(Bindings bindings) => [
    for (final binding in bindings)
      if (binding.input case final GamepadInputCombination gamepadInput)
        (slot: gamepadInput.slot, state: gamepadInput.inputs, binding: binding),
  ];

  void _startRepeatDelay() {
    _repeatTimer?.cancel();
    _delayTimer?.cancel();

    if (_state.entries.any((e) => e.value.isNotEmpty)) {
      _delayTimer = Timer(_repeatDelay, _startRepeat);
    }
  }

  void _startRepeat() {
    _scheduleRepeat(_initialRepeatInterval);
  }

  void _scheduleRepeat(Duration interval) {
    _repeatTimer?.cancel();
    _repeatTimer = Timer(interval, () {
      final actions = _getActions(slotRegistry.gamepadIdFor);

      if (actions.isEmpty) {
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

      _scheduleRepeat(_accelerate(interval));
    });
  }

  Duration _accelerate(Duration interval) {
    final next = interval * _repeatAcceleration;

    return next < _minRepeatInterval ? _minRepeatInterval : next;
  }

  void _stopRepeat() {
    _delayTimer?.cancel();
    _repeatTimer?.cancel();
  }
}
