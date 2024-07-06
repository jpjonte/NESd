import 'dart:async';

import 'package:flutter/widgets.dart' hide Router;
import 'package:nes/nes/nes.dart';
import 'package:nes/ui/emulator/input/action.dart';
import 'package:nes/ui/emulator/input/intents.dart';
import 'package:nes/ui/emulator/nes_controller.dart';
import 'package:nes/ui/emulator/save_manager.dart';
import 'package:nes/ui/router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'action_handler.g.dart';

typedef NesActionEvent = ({NesAction action, double value});

@riverpod
ActionStream actionStream(ActionStreamRef ref) {
  final stream = ActionStream();

  ref.onDispose(stream.dispose);

  return stream;
}

class ActionStream {
  Stream<NesActionEvent> get stream => _streamController.stream;

  final _streamController = StreamController<NesActionEvent>.broadcast();

  void add(NesActionEvent event) {
    _streamController.add(event);
  }

  void dispose() {
    _streamController.close();
  }
}

@riverpod
ActionHandler actionHandler(ActionHandlerRef ref) {
  final actionStream = ref.watch(actionStreamProvider);

  final handler = ActionHandler(
    nes: ref.watch(nesControllerProvider),
    nesController: ref.watch(nesControllerProvider.notifier),
    router: ref.read(routerProvider),
    saveManager: ref.watch(saveManagerProvider),
    actionStream: actionStream.stream,
  );

  ref.onDispose(() => handler.dispose());

  return handler;
}

class ActionHandler {
  ActionHandler({
    required this.nes,
    required this.nesController,
    required this.router,
    required this.saveManager,
    required Stream<NesActionEvent> actionStream,
  }) {
    _actionSubscription = actionStream.listen(handleAction);

    router.addListener(_updateRoute);
  }

  final NES? nes;
  final NesController nesController;
  final Router router;
  final SaveManager saveManager;

  late final StreamSubscription<NesActionEvent> _actionSubscription;

  bool enabled = true;

  bool get _inGame => _currentRoute == EmulatorRoute.name && nes != null;

  String _currentRoute = EmulatorRoute.name;

  void dispose() {
    _actionSubscription.cancel();

    router.removeListener(_updateRoute);
  }

  void handleAction(NesActionEvent event) {
    if (!enabled) {
      return;
    }

    if (event.value > 0.5) {
      handleActionDown(event.action);
    } else {
      handleActionUp(event.action);
    }
  }

  void handleActionDown(NesAction action) {
    if (action is OpenMenu) {
      if (_currentRoute == SettingsRoute.name) {
        nesController
          ..lifeCycleListenerEnabled = true
          ..resume();

        router.navigate(const EmulatorRoute());
      } else {
        nesController
          ..lifeCycleListenerEnabled = false
          ..suspend();

        router.navigate(const SettingsRoute());
      }

      return;
    }

    if (_inGame) {
      _handleActionDownInGame(action);
    } else {
      _handleActionDownInMenu(action);
    }
  }

  void handleActionUp(NesAction action) {
    switch (action) {
      case ControllerPress():
        if (_inGame) {
          nes?.buttonUp(action.controller, action.button);
        }
      default:
      // no-op
    }
  }

  void _handleActionDownInGame(NesAction action) {
    switch (action) {
      case ControllerPress():
        nes?.buttonDown(action.controller, action.button);
      case SaveState():
        _saveState(action.slot);
      case LoadState():
        _loadState(action.slot);
      case TogglePauseAction():
        nes?.togglePause();
      case PauseAction(paused: final paused):
        if (paused) {
          nes?.pause();
        } else {
          nes?.unpause();
        }
      case StopAction():
        nesController.stop();
      case DecreaseVolume():
        nesController.volume -= 0.1;
      case IncreaseVolume():
        nesController.volume += 0.1;
      default:
      // no-op
    }
  }

  void _handleActionDownInMenu(NesAction action) {
    switch (action) {
      case NextInput():
        _sendIntent(const NextFocusIntent());
      case PreviousInput():
        _sendIntent(const PreviousFocusIntent());
      case Confirm():
        _sendIntent(const ActivateIntent());
      case SecondaryAction():
        _sendIntent(const SecondaryActionIntent());
      case Cancel():
        router.maybePop();
      case MenuDecrease():
        _sendIntent(const DecreaseIntent());
      case MenuIncrease():
        _sendIntent(const IncreaseIntent());
      case PreviousTab():
        _sendIntent(const PreviousTabIntent());
      case NextTab():
        _sendIntent(const NextTabIntent());
      default:
      // no-op
    }
  }

  void _saveState(int slot) {
    if (nes case final nes?) {
      saveManager.saveState(nes, slot);
    }
  }

  void _loadState(int slot) {
    if (nes case final nes?) {
      saveManager.loadState(nes, slot);
    }
  }

  void _updateRoute() {
    _currentRoute = router.current.name;
  }

  void _sendIntent(Intent intent) {
    final focus = WidgetsBinding.instance.focusManager.primaryFocus;

    final context = focus?.context;

    if (context != null) {
      final flutterAction = Actions.maybeFind(context, intent: intent);

      if (flutterAction != null) {
        Actions.of(context).invokeAction(flutterAction, intent);
      }
    }
  }
}
