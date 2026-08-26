import 'package:flutter/services.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/bound_action.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'keyboard_input_handler.g.dart';

typedef KeyMap = Map<Set<LogicalKeyboardKey>, Binding>;

@riverpod
KeyboardInputHandler keyboardInputHandler(Ref ref) {
  final bindings = ref.watch(
    settingsControllerProvider.select((settings) => settings.bindings),
  );

  final actionStream = ref.watch(actionStreamProvider);

  return KeyboardInputHandler(bindings: bindings, actionStream: actionStream);
}

class KeyboardInputHandler {
  KeyboardInputHandler({
    required Bindings bindings,
    required this.actionStream,
  }) {
    _bindings = _buildBindingMap(bindings);
  }

  final ActionStream actionStream;

  late final KeyMap _bindings;

  bool handleKeyEvent(KeyEvent event) {
    if (event is KeyRepeatEvent) {
      return true;
    }

    final key = event.logicalKey;

    // let Flutter track the pressed keys so we don't miss anything
    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;

    if (event is KeyDownEvent) {
      final previousActions = _getActions(pressedKeys.difference({key}));
      final currentActions = _getActions(pressedKeys);

      // handle all actions that are new
      // until we reach an action with lower priority
      return _addActions(
        1.0,
        currentActions,
        previousActions,
        highesPriorityOnly: true,
      );
    } else if (event is KeyUpEvent) {
      final previousActions = _getActions({...pressedKeys, key});
      final currentActions = _getActions(pressedKeys);

      // handle all actions that are no longer active
      return _addActions(0.0, previousActions, currentActions);
    }

    return false;
  }

  // get actions that match the pressed keys, sorted by highest priority first
  // priority = number of keys pressed
  List<BoundAction> _getActions(Set<LogicalKeyboardKey> pressedKeys) {
    final expandedKeys = {
      for (final key in pressedKeys) ...[key, ...key.synonyms],
    };

    final actions = <BoundAction>[];

    for (final MapEntry(key: input, value: binding) in _bindings.entries) {
      if (expandedKeys.containsAll(input)) {
        actions.add(
          BoundAction(
            priority: input.length,
            action: binding.action,
            bindingType: binding.type,
          ),
        );
      }
    }

    actions.sort((a, b) => b.priority.compareTo(a.priority));

    return actions;
  }

  bool _addActions(
    double value,
    List<BoundAction> baseActions,
    List<BoundAction> compareActions, {
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
        actionStream.add(
          InputActionEvent(
            action: action.action,
            value: value,
            bindingType: action.bindingType,
          ),
        );
        triggered = true;
      }
    }

    return triggered;
  }

  KeyMap _buildBindingMap(Bindings bindings) {
    final bindingMap = <Set<LogicalKeyboardKey>, Binding>{};

    for (final binding in bindings) {
      if (binding.input case final KeyboardInputCombination input) {
        bindingMap[input.keys] = binding;
      }
    }

    return bindingMap;
  }
}
