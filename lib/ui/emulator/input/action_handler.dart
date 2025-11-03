import 'dart:async';

import 'package:flutter/widgets.dart' hide Router;
import 'package:nesd/audio/audio_output.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
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
    audioOutput: ref.watch(audioOutputProvider),
    actionStream: actionStream.stream,
  );

  ref.onDispose(handler.dispose);

  final routeSubscription = ref.listen(
    routerObserverProvider,
    (_, route) => handler._currentRoute = route,
  );

  ref.onDispose(routeSubscription.close);

  return handler;
}

class ActionHandler {
  ActionHandler({
    required this.nes,
    required this.nesController,
    required this.router,
    required this.romManager,
    required this.audioOutput,
    required Stream<InputActionEvent> actionStream,
  }) {
    _actionSubscription = actionStream.listen(handleAction);
  }

  final NES? nes;
  final NesController nesController;
  final Router router;
  final RomManager romManager;
  final AudioOutput audioOutput;

  late final StreamSubscription<InputActionEvent> _actionSubscription;

  bool enabled = true;

  bool get _inGame => _currentRoute == EmulatorRoute.name;

  String? _currentRoute = MainRoute.name;

  void dispose() {
    _actionSubscription.cancel();
  }

  void handleAction(InputActionEvent event) {
    if (!enabled) {
      return;
    }

    if (event.value > 0.5) {
      if (event.bindingType == BindingType.toggle && _inGame) {
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
    if (_inGame) {
      _handleActionDownInGame(action);
    } else {
      _handleActionDownInMenu(action);
    }
  }

  void _handleActionUp(InputAction action) {
    switch (action) {
      case ControllerPress():
        if (_inGame) {
          nes?.buttonUp(action.controller, action.button);
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
        nes?.buttonToggle(action.controller, action.button);
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
        nes?.buttonDown(action.controller, action.button);
      case SaveState():
        _saveState(action.slot);
      case LoadState():
        _loadState(action.slot);
      case FastForward():
        nes?.fastForward = true;
      case Rewind():
        nes?.rewind = true;
      case PauseAction(paused: final paused):
        if (paused) {
          nes?.pause();
        } else {
          nes?.unpause();
        }
      case StopAction():
        nesController.stop();
        router.navigate(const MainRoute());
      case DecreaseVolume():
        audioOutput.volume -= 0.1;
      case IncreaseVolume():
        audioOutput.volume += 0.1;
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
        _sendIntent(const DirectionalFocusIntent(TraversalDirection.up));
      case InputDown():
        _sendIntent(const DirectionalFocusIntent(TraversalDirection.down));
      case InputLeft():
        _sendIntent(const DirectionalFocusIntent(TraversalDirection.left));
      case InputRight():
        _sendIntent(const DirectionalFocusIntent(TraversalDirection.right));
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
      // no-op
    }
  }

  void _saveState(int slot) {
    nesController.saveState(slot);
  }

  void _loadState(int slot) {
    nesController.loadState(slot);
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
