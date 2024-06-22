import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nes/ui/emulator/input/action.dart';
import 'package:nes/ui/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'keyboard_input.g.dart';

typedef PriorityAction = ({int priority, NesAction action});
typedef KeyMap = Map<Set<LogicalKeyboardKey>, NesAction>;

@riverpod
KeyboardInput keyboardInput(KeyboardInputRef ref) {
  final keyBindings = ref.watch(
    settingsControllerProvider.select((settings) => settings.keyMap),
  );

  return KeyboardInput(keyBindings: keyBindings);
}

class KeyboardInput {
  KeyboardInput({required List<KeyBinding> keyBindings}) {
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);

    _keyMap = _buildKeyMap(keyBindings);
  }

  Stream<NesAction> get keyDownStream => _keyDownStreamController.stream;
  Stream<NesAction> get keyUpStream => _keyUpStreamController.stream;

  final _keyDownStreamController = StreamController<NesAction>.broadcast();
  final _keyUpStreamController = StreamController<NesAction>.broadcast();

  final _pressedKeys = <LogicalKeyboardKey>{};

  late final KeyMap _keyMap;

  void dispose() {
    _keyDownStreamController.close();
    _keyUpStreamController.close();
  }

  bool _handleKeyEvent(KeyEvent event) {
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
    final mappedKey = _mapKey(event.logicalKey);

    if (event is KeyDownEvent) {
      _pressedKeys.add(mappedKey);
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(mappedKey);
    }
  }

  // get actions that match the pressed keys, sorted by highest priority first
  // priority = number of keys pressed
  List<PriorityAction> _getActions() {
    final actions = <PriorityAction>[];

    for (final entry in _keyMap.entries) {
      if (_pressedKeys.containsAll(entry.key)) {
        actions.add((priority: entry.key.length, action: entry.value));
      }
    }

    actions.sort((a, b) => b.priority.compareTo(a.priority));

    return actions;
  }

  // map specific (left, right) keys to general keys
  LogicalKeyboardKey _mapKey(LogicalKeyboardKey logicalKey) {
    return switch (logicalKey) {
      LogicalKeyboardKey.shiftLeft ||
      LogicalKeyboardKey.shiftRight =>
        LogicalKeyboardKey.shift,
      LogicalKeyboardKey.controlLeft ||
      LogicalKeyboardKey.controlRight =>
        LogicalKeyboardKey.control,
      LogicalKeyboardKey.altLeft ||
      LogicalKeyboardKey.altRight =>
        LogicalKeyboardKey.alt,
      LogicalKeyboardKey.metaLeft ||
      LogicalKeyboardKey.metaRight =>
        LogicalKeyboardKey.meta,
      _ => logicalKey,
    };
  }

  KeyMap _buildKeyMap(List<KeyBinding> keyBindings) {
    final keyMap = <Set<LogicalKeyboardKey>, NesAction>{};

    for (final keyBinding in keyBindings) {
      final keys = _getKeys(keyBinding.keys);
      final action = _getAction(keyBinding.action);

      if (action == null) {
        continue;
      }

      keyMap[keys] = action;
    }

    return keyMap;
  }

  Set<LogicalKeyboardKey> _getKeys(Set<int> keyIds) {
    return keyIds
        .map((keyId) => LogicalKeyboardKey.findKeyByKeyId(keyId))
        .where((k) => k != null)
        .cast<LogicalKeyboardKey>()
        .toSet();
  }

  NesAction? _getAction(String code) {
    for (final action in allActions) {
      if (action.code == code) {
        return action;
      }
    }

    return null;
  }
}
