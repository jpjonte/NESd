import 'package:nes/nes/nes.dart';
import 'package:nes/ui/emulator/input/action.dart';
import 'package:nes/ui/emulator/input/gamepad_input_handler.dart';
import 'package:nes/ui/emulator/input/keyboard_input_handler.dart';
import 'package:nes/ui/emulator/nes_controller.dart';
import 'package:nes/ui/emulator/save_manager.dart';
import 'package:nes/ui/router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'action_handler.g.dart';

@riverpod
ActionHandler actionHandler(ActionHandlerRef ref) {
  final handler = ActionHandler(
    nes: ref.watch(nesControllerProvider),
    nesController: ref.watch(nesControllerProvider.notifier),
    router: ref.watch(routerProvider),
    saveManager: ref.watch(saveManagerProvider),
  );

  final keyboardSubscription = ref.listen(
    keyboardInputHandlerProvider,
    (_, input) {
      input
        ..keyDownStream.listen(handler.handleActionDown)
        ..keyUpStream.listen(handler.handleActionUp);
    },
    fireImmediately: true,
  );

  ref.onDispose(() => keyboardSubscription.close());

  final gamepadSubscription = ref.listen(
    gamepadInputHandlerProvider,
    (_, input) {
      input
        ..buttonDownStream.listen(handler.handleActionDown)
        ..buttonUpStream.listen(handler.handleActionUp);
    },
    fireImmediately: true,
  );

  ref.onDispose(() => gamepadSubscription.close());

  return handler;
}

class ActionHandler {
  const ActionHandler({
    required this.nes,
    required this.nesController,
    required this.router,
    required this.saveManager,
  });

  final NES? nes;
  final NesController nesController;
  final Router router;
  final SaveManager saveManager;

  void handleActionDown(NesAction action) {
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
      case OpenSettings():
        nesController
          ..lifeCycleListenerEnabled = false
          ..suspend();

        router.navigate(const SettingsRoute());
    }
  }

  void handleActionUp(NesAction action) {
    switch (action) {
      case ControllerPress():
        nes?.buttonUp(action.controller, action.button);
      default:
      // no-op
    }
  }

  void _saveState(int slot) {
    if (nes case final state?) {
      saveManager.saveState(state, slot);
    }
  }

  void _loadState(int slot) {
    if (nes case final state?) {
      saveManager.loadState(state, slot);
    }
  }
}
