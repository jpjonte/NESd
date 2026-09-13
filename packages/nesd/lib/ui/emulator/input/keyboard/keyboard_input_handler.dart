import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nesd/ui/emulator/emulator_active.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/bound_action.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/rewind/rewind_scrub_controller.dart';
import 'package:nesd/ui/emulator/tools/tool_focus_controller.dart';
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

  final handler = KeyboardInputHandler(
    bindings: bindings,
    actionStream: actionStream,
  );

  final scrubSubscription = ref.listen(
    rewindScrubControllerProvider,
    (_, state) => handler.scrubOpen = state.open,
    fireImmediately: true,
  );

  ref.onDispose(scrubSubscription.close);

  void updateMode() {
    handler.menuMode =
        !ref.read(emulatorActiveProvider) ||
        ref.read(toolFocusControllerProvider);
  }

  final activeSubscription = ref.listen(
    emulatorActiveProvider,
    (_, _) => updateMode(),
    fireImmediately: true,
  );
  final toolsSubscription = ref.listen(
    toolFocusControllerProvider,
    (_, _) => updateMode(),
    fireImmediately: true,
  );

  ref
    ..onDispose(activeSubscription.close)
    ..onDispose(toolsSubscription.close);

  return handler;
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

  bool scrubOpen = false;

  final _activeActions = <InputAction>{};

  bool menuMode = false;

  static const _repeatingMenuActions = <InputAction>{
    previousInput,
    nextInput,
    inputUp,
    inputDown,
    inputLeft,
    inputRight,
    menuDecrease,
    menuIncrease,
  };

  static const _textFieldActions = <InputAction>{
    previousInput,
    nextInput,
    inputUp,
    inputDown,
    previousTab,
    nextTab,
    confirm,
    openMenu,
  };

  bool handleKeyEvent(KeyEvent event) {
    final inTextField = _focusInTextField();

    if (event is KeyRepeatEvent) {
      if (scrubOpen) {
        return _handleKeyRepeat(_allowAll);
      }

      if (menuMode) {
        return _handleKeyRepeat(
          (action) =>
              _repeatingMenuActions.contains(action) &&
              (!inTextField || _textFieldActions.contains(action)) &&
              !isInGameAction(action),
        );
      }

      return true;
    }

    final baseAllowed = inTextField ? _textFieldActions.contains : _allowAll;

    bool allowed(InputAction action) =>
        baseAllowed(action) && (!menuMode || !isInGameAction(action));

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
        allowed,
        highesPriorityOnly: true,
      );
    } else if (event is KeyUpEvent) {
      final previousActions = _getActions({...pressedKeys, key});
      final currentActions = _getActions(pressedKeys);

      // handle all actions that are no longer active
      return _addActions(0.0, previousActions, currentActions, allowed);
    }

    return false;
  }

  static bool _allowAll(InputAction action) => true;

  bool _handleKeyRepeat(bool Function(InputAction) allowed) {
    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
    final currentActions = _getActions(pressedKeys);

    return _addActions(
      1.0,
      currentActions,
      const [],
      allowed,
      highesPriorityOnly: true,
    );
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
    List<BoundAction> compareActions,
    bool Function(InputAction) allowed, {
    bool highesPriorityOnly = false,
  }) {
    int? priority;
    var triggered = false;

    for (final action in baseActions) {
      priority ??= action.priority;

      if (highesPriorityOnly && action.priority < priority) {
        break;
      }

      if (value == 0.0) {
        if (!_activeActions.contains(action.action)) {
          continue;
        }
      } else if (!allowed(action.action)) {
        continue;
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

        if (value == 0.0) {
          _activeActions.remove(action.action);
        } else {
          _activeActions.add(action.action);
        }
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

  static bool _focusInTextField() =>
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorStateOfType<EditableTextState>() !=
      null;
}
