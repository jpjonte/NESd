import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nes/ui/emulator/input/action.dart';
import 'package:nes/ui/settings/controls/binding.dart';
import 'package:nes/ui/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'keyboard_input_handler.g.dart';

typedef PriorityAction = ({int priority, NesAction action});
typedef KeyMap = Map<Set<LogicalKeyboardKey>, NesAction>;

@riverpod
KeyboardInputHandler keyboardInputHandler(KeyboardInputHandlerRef ref) {
  final bindings = ref.watch(
    settingsControllerProvider.select((settings) => settings.bindings),
  );

  final input = KeyboardInputHandler(bindings);

  ref.onDispose(input.dispose);

  return input;
}

class KeyboardInputHandler {
  KeyboardInputHandler(Map<NesAction, InputCombination> bindings) {
    _bindings = _buildBindingMap(bindings);
  }

  Stream<NesAction> get keyDownStream => _keyDownStreamController.stream;
  Stream<NesAction> get keyUpStream => _keyUpStreamController.stream;

  final _keyDownStreamController = StreamController<NesAction>.broadcast();
  final _keyUpStreamController = StreamController<NesAction>.broadcast();

  final _pressedKeys = <LogicalKeyboardKey>{};

  late final KeyMap _bindings;

  void dispose() {
    _keyDownStreamController.close();
    _keyUpStreamController.close();
  }

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
        _keyDownStreamController,
        currentActions,
        previousActions,
        highesPriorityOnly: true,
      );
    } else if (event is KeyUpEvent) {
      // handle all actions that are no longer active
      return _addActions(
        _keyUpStreamController,
        previousActions,
        currentActions,
      );
    }

    return false;
  }

  bool _addActions(
    StreamController<NesAction> stream,
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
        stream.add(action.action);
        triggered = true;
      }
    }

    return triggered;
  }

  void _updatePressedKeys(KeyEvent event) {
    final key = event.logicalKey;

    if (event is KeyDownEvent) {
      _pressedKeys.addAll([key, ...key.synonyms]);
    } else if (event is KeyUpEvent) {
      _pressedKeys.removeAll([key, ...key.synonyms]);
    }
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

  KeyMap _buildBindingMap(Map<NesAction, InputCombination> bindings) {
    return {
      for (final MapEntry(key: action, value: input) in bindings.entries)
        if (input case final KeyboardInputCombination input) input.keys: action,
    };
  }
}
