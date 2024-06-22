import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nes/nes/bus.dart';
import 'package:nes/ui/emulator/input/action.dart';

typedef PriorityAction = ({int priority, NesAction action});

class KeyboardInput {
  KeyboardInput() {
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  Stream<NesAction> get keyDownStream => _keyDownStreamController.stream;
  Stream<NesAction> get keyUpStream => _keyUpStreamController.stream;

  final _keyDownStreamController = StreamController<NesAction>.broadcast();
  final _keyUpStreamController = StreamController<NesAction>.broadcast();

  final _pressedKeys = <LogicalKeyboardKey>{};

  late final _keyMap = {
    {LogicalKeyboardKey.arrowUp}: const ControllerButtonAction(0, NesButton.up),
    {LogicalKeyboardKey.arrowDown}:
        const ControllerButtonAction(0, NesButton.down),
    {LogicalKeyboardKey.arrowLeft}:
        const ControllerButtonAction(0, NesButton.left),
    {LogicalKeyboardKey.arrowRight}:
        const ControllerButtonAction(0, NesButton.right),
    {LogicalKeyboardKey.enter}:
        const ControllerButtonAction(0, NesButton.start),
    {LogicalKeyboardKey.shift}:
        const ControllerButtonAction(0, NesButton.select),
    {LogicalKeyboardKey.keyZ}: const ControllerButtonAction(0, NesButton.a),
    {LogicalKeyboardKey.keyX}: const ControllerButtonAction(0, NesButton.b),
    {LogicalKeyboardKey.digit1}: const LoadState(1),
    {LogicalKeyboardKey.digit1, LogicalKeyboardKey.shift}: const SaveState(1),
    {LogicalKeyboardKey.digit2}: const LoadState(2),
    {LogicalKeyboardKey.digit2, LogicalKeyboardKey.shift}: const SaveState(2),
    {LogicalKeyboardKey.digit3}: const LoadState(3),
    {LogicalKeyboardKey.digit3, LogicalKeyboardKey.shift}: const SaveState(3),
    {LogicalKeyboardKey.digit4}: const LoadState(4),
    {LogicalKeyboardKey.digit4, LogicalKeyboardKey.shift}: const SaveState(4),
    {LogicalKeyboardKey.digit5}: const LoadState(5),
    {LogicalKeyboardKey.digit5, LogicalKeyboardKey.shift}: const SaveState(5),
    {LogicalKeyboardKey.digit6}: const LoadState(6),
    {LogicalKeyboardKey.digit6, LogicalKeyboardKey.shift}: const SaveState(6),
    {LogicalKeyboardKey.digit7}: const LoadState(7),
    {LogicalKeyboardKey.digit7, LogicalKeyboardKey.shift}: const SaveState(7),
    {LogicalKeyboardKey.digit8}: const LoadState(8),
    {LogicalKeyboardKey.digit8, LogicalKeyboardKey.shift}: const SaveState(8),
    {LogicalKeyboardKey.digit9}: const LoadState(9),
    {LogicalKeyboardKey.digit9, LogicalKeyboardKey.shift}: const SaveState(9),
    {LogicalKeyboardKey.digit0}: const LoadState(0),
    {LogicalKeyboardKey.digit0, LogicalKeyboardKey.shift}: const SaveState(0),
  };

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
}
