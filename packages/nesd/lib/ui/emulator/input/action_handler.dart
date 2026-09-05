import 'dart:async';

import 'package:flutter/widgets.dart' hide Router;
import 'package:nesd/log/log.dart';
import 'package:nesd/ui/emulator/emulator_active.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/remote_nes.dart';
import 'package:nesd/ui/emulator/rewind/rewind_scrub_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/emulator/tools/emulator_tools_controller.dart';
import 'package:nesd/ui/emulator/tools/tool_focus_controller.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'action_handler.g.dart';

class InputActionEvent {
  const InputActionEvent({
    required this.action,
    required this.value,
    required this.bindingType,
  });

  final InputAction action;
  final double value;
  final BindingType bindingType;
}

@riverpod
ActionStream actionStream(Ref ref) {
  final stream = ActionStream();

  ref.onDispose(stream.dispose);

  return stream;
}

class ActionStream {
  Stream<InputActionEvent> get stream => _streamController.stream;

  final _streamController = StreamController<InputActionEvent>.broadcast();

  void add(InputActionEvent event) {
    _streamController.add(event);
  }

  void dispose() {
    _streamController.close();
  }
}

@riverpod
ActionHandler actionHandler(Ref ref) {
  final actionStream = ref.watch(actionStreamProvider);

  final handler = ActionHandler(
    nes: ref.watch(nesStateProvider),
    nesController: ref.watch(nesControllerProvider),
    router: ref.read(routerProvider),
    romManager: ref.watch(romManagerProvider),
    settingsController: ref.read(settingsControllerProvider.notifier),
    toolsController: ref.watch(emulatorToolsControllerProvider.notifier),
    toolFocusController: ref.watch(toolFocusControllerProvider.notifier),
    scrubController: ref.watch(rewindScrubControllerProvider.notifier),
    actionStream: actionStream.stream,
  );

  ref.onDispose(handler.dispose);

  final routeSubscription = ref.listen(
    emulatorActiveProvider,
    (_, active) => handler.emulatorActive = active,
    fireImmediately: true,
  );

  ref.onDispose(routeSubscription.close);

  final toolFocusSubscription = ref.listen(
    toolFocusControllerProvider,
    (_, focused) => handler.toolsFocused = focused,
    fireImmediately: true,
  );

  ref.onDispose(toolFocusSubscription.close);

  final scrubSubscription = ref.listen(
    rewindScrubControllerProvider,
    (_, scrubState) => handler.scrubState = scrubState,
    fireImmediately: true,
  );

  ref.onDispose(scrubSubscription.close);

  return handler;
}

class ActionHandler {
  ActionHandler({
    required this.nes,
    required this.nesController,
    required this.router,
    required this.romManager,
    required this.settingsController,
    required this.toolsController,
    required this.toolFocusController,
    required this.scrubController,
    required Stream<InputActionEvent> actionStream,
  }) {
    _actionSubscription = actionStream.listen(handleAction);
  }

  final RemoteNes? nes;
  final NesController nesController;
  final Router router;
  final RomManager romManager;
  final SettingsController settingsController;
  final EmulatorToolsController toolsController;
  final ToolFocusController toolFocusController;
  final RewindScrubController scrubController;

  late final StreamSubscription<InputActionEvent> _actionSubscription;

  final _heldToggleTools = <EmulatorTool>{};

  bool _focusToolsHeld = false;

  bool _rewindTimelineHeld = false;

  InputAction? _scrubHoldAction;

  int _scrubHoldRun = 0;

  bool enabled = true;

  bool emulatorActive = false;

  bool toolsFocused = false;

  RewindScrubState scrubState = const RewindScrubState.closed();

  bool get _inGame => emulatorActive;

  void dispose() {
    _actionSubscription.cancel();
  }

  void handleAction(InputActionEvent event) {
    if (!enabled) {
      return;
    }

    if (event.action case ToggleTool(tool: final tool)) {
      // Edge-triggered: hold-to-repeat re-emissions and analog jitter
      // around the threshold must not toggle again (#251).
      if (event.value > 0.5) {
        if (_heldToggleTools.add(tool)) {
          toolsController.toggle(tool);
        }
      } else {
        _heldToggleTools.remove(tool);
      }

      return;
    }

    if (event.action case FocusTools()) {
      if (event.value > 0.5) {
        if (!_focusToolsHeld) {
          _focusToolsHeld = true;

          toolFocusController.toggle();
        }
      } else {
        _focusToolsHeld = false;
      }

      return;
    }

    if (event.action case RewindTimelineAction()) {
      if (event.value <= 0.5) {
        _rewindTimelineHeld = false;

        return;
      }

      if (_rewindTimelineHeld) {
        return;
      }

      _rewindTimelineHeld = true;
    }

    if (event.value > 0.5) {
      if (event.bindingType == BindingType.toggle &&
          _inGame &&
          !scrubState.open) {
        _handleActionToggleInGame(event.action);

        return;
      }

      _handleActionDown(event.action);
    } else {
      if (event.bindingType == BindingType.toggle) {
        return;
      }

      _handleActionUp(event.action);
    }
  }

  void _handleActionDown(InputAction action) {
    if (!_inGame) {
      _handleActionDownInMenu(action);

      return;
    }

    if (scrubState.open) {
      _handleActionDownInScrub(action);

      return;
    }

    if (toolsFocused) {
      _handleActionDownInTools(action);

      return;
    }

    _handleActionDownInGame(action);
  }

  void _handleActionDownInTools(InputAction action) {
    switch (action) {
      case Cancel():
        toolFocusController.exit();
      case OpenMenu():
        router.navigate(const MenuRoute());
      default:
        _handleActionDownInMenu(action);
    }
  }

  void _handleActionDownInScrub(InputAction action) {
    switch (action) {
      case InputLeft():
        _recordScrubHold(action);
        scrubController.moveBy(-_scrubSecondsStep());
      case InputRight():
        _recordScrubHold(action);
        scrubController.moveBy(_scrubSecondsStep());
      case InputUp() || PreviousInput():
        _resetScrubHold();
        scrubController.moveBy(1);
      case InputDown() || NextInput():
        _resetScrubHold();
        scrubController.moveBy(-1);
      case Confirm():
        _resetScrubHold();
        scrubController.commit();
      case Cancel() || RewindTimelineAction():
        _resetScrubHold();
        scrubController.cancel();
      default:
      // every other action is swallowed: the game must not see input
      // while the timeline owns it
    }
  }

  void _recordScrubHold(InputAction action) {
    _scrubHoldRun = action == _scrubHoldAction ? _scrubHoldRun + 1 : 1;
    _scrubHoldAction = action;
  }

  int _scrubSecondsStep() => _oneSecondInCaptures() * _scrubHoldMultiplier();

  int _scrubHoldMultiplier() {
    const rampSteps = 10;
    const maxMultiplier = 4;

    final multiplier = 1 + (_scrubHoldRun - 1) ~/ rampSteps;

    return multiplier > maxMultiplier ? maxMultiplier : multiplier;
  }

  int _oneSecondInCaptures() =>
      scrubState.frameRate ~/ scrubState.captureInterval;

  void _resetScrubHold() {
    _scrubHoldAction = null;
    _scrubHoldRun = 0;
  }

  void _handleActionUp(InputAction action) {
    switch (action) {
      case ControllerPress():
        if (_inGame) {
          nes?.buttonUp(action.controller, action.button, turbo: action.turbo);
        }
      case FastForward():
        if (_inGame) {
          nes?.fastForward = false;
        }

      case Rewind():
        if (_inGame) {
          nes?.rewind = false;
        }
      case PauseAction(paused: final paused):
        if (_inGame) {
          if (paused) {
            nes?.unpause();
          } else {
            nes?.pause();
          }
        }
      default:
      // no-op
    }
  }

  void _handleActionToggleInGame(InputAction action) {
    switch (action) {
      case ControllerPress():
        nes?.buttonToggle(
          action.controller,
          action.button,
          turbo: action.turbo,
        );
      case FastForward():
        nes?.toggleFastForward();
      case Rewind():
        nes?.toggleRewind();
      case PauseAction():
        nes?.togglePause();
      default:
      // no-op
    }
  }

  void _handleActionDownInGame(InputAction action) {
    switch (action) {
      case ControllerPress():
        nes?.buttonDown(action.controller, action.button, turbo: action.turbo);
      case SaveState():
        _saveState(action.slot);
      case LoadState():
        _loadState(action.slot);
      case FastForward():
        nes?.fastForward = true;
      case Rewind():
        nes?.rewind = true;
      case RewindTimelineAction():
        _resetScrubHold();
        nes?.unpause();
        unawaited(scrubController.open());
      case PauseAction(paused: final paused):
        if (paused) {
          nes?.pause();
        } else {
          nes?.unpause();
        }
      case ResetAction():
        unawaited(nesController.reset());
      case StopAction():
        unawaited(nesController.stop());
        router.navigate(const MainRoute());
      case DecreaseVolume():
        settingsController.volume = (settingsController.volume - 0.1).clamp(
          0,
          1,
        );
      case IncreaseVolume():
        settingsController.volume = (settingsController.volume + 0.1).clamp(
          0,
          1,
        );
      case OpenMenu():
        router.navigate(const MenuRoute());
      default:
      // no-op
    }
  }

  void _handleActionDownInMenu(InputAction action) {
    switch (action) {
      case NextInput():
        _sendIntent(const NextFocusIntent());
      case PreviousInput():
        _sendIntent(const PreviousFocusIntent());
      case InputUp():
        _sendIntent(
          const DirectionalFocusIntent(
            TraversalDirection.up,
            ignoreTextFields: false,
          ),
        );
      case InputDown():
        _sendIntent(
          const DirectionalFocusIntent(
            TraversalDirection.down,
            ignoreTextFields: false,
          ),
        );
      case InputLeft():
        _sendIntent(
          const DirectionalFocusIntent(
            TraversalDirection.left,
            ignoreTextFields: false,
          ),
        );
      case InputRight():
        _sendIntent(
          const DirectionalFocusIntent(
            TraversalDirection.right,
            ignoreTextFields: false,
          ),
        );
      case Confirm():
        _sendIntent(const ActivateIntent());
      case SecondaryAction():
        _sendIntent(const SecondaryActionIntent());
      case Cancel():
        _sendIntent(const DismissIntent());
      case MenuDecrease():
        _sendIntent(const DecreaseIntent());
      case MenuIncrease():
        _sendIntent(const IncreaseIntent());
      case PreviousTab():
        _sendIntent(const PreviousTabIntent());
      case NextTab():
        _sendIntent(const NextTabIntent());
      case OpenMenu():
        router.navigate(const EmulatorRoute());
      default:
        _warnIfInGameAction(action);
    }
  }

  void _warnIfInGameAction(InputAction action) {
    assert(() {
      if (_isInGameAction(action)) {
        final reason = toolsFocused
            ? 'the tool panel owns input'
            : 'the emulator is not the active screen';

        log.input.debug(
          'ActionHandler: dropped in-game action "${action.code}" - $reason',
        );
      }

      return true;
    }());
  }

  bool _isInGameAction(InputAction action) => switch (action) {
    ControllerPress() ||
    SaveState() ||
    LoadState() ||
    FastForward() ||
    Rewind() ||
    RewindTimelineAction() ||
    PauseAction() ||
    ResetAction() ||
    StopAction() ||
    DecreaseVolume() ||
    IncreaseVolume() => true,
    _ => false,
  };

  void _saveState(int slot) {
    unawaited(nesController.saveState(slot));
  }

  void _loadState(int slot) {
    unawaited(nesController.loadState(slot));
  }

  void _sendIntent(Intent intent) {
    final focus = WidgetsBinding.instance.focusManager.primaryFocus;

    final context = focus?.context;

    if (context == null) {
      return;
    }

    final flutterAction = Actions.maybeFind(context, intent: intent);

    if (flutterAction == null) {
      return;
    }

    if (!flutterAction.isEnabled(intent)) {
      return;
    }

    Actions.of(context).invokeAction(flutterAction, intent);
  }
}
