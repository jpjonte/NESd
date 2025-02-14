import 'package:flutter/services.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'keyboard_input_handler.g.dart';

typedef PriorityAction = ({int priority, InputAction action});
typedef KeyMap = Map<Set<LogicalKeyboardKey>, InputAction>;

@riverpod
KeyboardInputHandler keyboardInputHandler(Ref ref) {
  final bindings = ref.watch(
    settingsControllerProvider.select((settings) => settings.bindings),
  );

  final actionStream = ref.watch(actionStreamProvider);

  return KeyboardInputHandler(
    bindings: bindings,
    actionStream: actionStream,
  );
}

class KeyboardInputHandler {
  KeyboardInputHandler({
    required BindingMap bindings,
    required this.actionStream,
  }) {
    _bindings = _buildBindingMap(bindings);
  }

  final ActionStream actionStream;

  late final KeyMap _bindings;

  final _pressedKeys = <LogicalKeyboardKey>{};

  bool handleKeyEvent(KeyEvent event) {
    if (event is KeyRepeatEvent) {
      return true;
    }

    // get actions that match the previously pressed keys
    final previousActions = _getActions();

    _updatePressedKeys(event);

    // get actions that match the currently pressed keys
    final currentActions = _getActions();

    if (event is KeyDownEvent) {
      // handle all actions that are new
      // until we reach an action with lower priority
      return _addActions(
        1.0,
        currentActions,
        previousActions,
        highesPriorityOnly: true,
      );
    } else if (event is KeyUpEvent) {
      // handle all actions that are no longer active
      return _addActions(
        0.0,
        previousActions,
        currentActions,
      );
    }

    return false;
  }

  // get actions that match the pressed keys, sorted by highest priority first
  // priority = number of keys pressed
  List<PriorityAction> _getActions() {
    final actions = <PriorityAction>[];

    for (final MapEntry(key: input, value: action) in _bindings.entries) {
      if (_pressedKeys.containsAll(input)) {
        actions.add((priority: input.length, action: action));
      }
    }

    actions.sort((a, b) => b.priority.compareTo(a.priority));

    return actions;
  }

  void _updatePressedKeys(KeyEvent event) {
    final key = event.logicalKey;

    if (event is KeyDownEvent) {
      _pressedKeys.addAll([key, ...key.synonyms]);
    } else if (event is KeyUpEvent) {
      _pressedKeys.removeAll([key, ...key.synonyms]);
    }
  }

  bool _addActions(
    double value,
    List<PriorityAction> baseActions,
    List<PriorityAction> compareActions, {
    bool highesPriorityOnly = false,
  }) {
    int? priority;
    var triggered = false;

    for (final action in baseActions) {
      priority ??= action.priority;

      if (highesPriorityOnly && action.priority < priority) {
        break;
      }

      if (!compareActions.contains(action)) {
        actionStream.add((action: action.action, value: value));
        triggered = true;
      }
    }

    return triggered;
  }

  KeyMap _buildBindingMap(BindingMap bindings) {
    return {
      for (final MapEntry(key: action, value: inputs) in bindings.entries)
        for (final input in inputs)
          if (input case final KeyboardInputCombination input)
            input.keys: action,
    };
  }
}
