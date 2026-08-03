import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart' hide reset;
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/settings.dart';

class _MockNesController extends Mock implements NesController {}

class _MockRouter extends Mock implements Router {}

class _MockRomManager extends Mock implements RomManager {}

class _MockSettingsController extends Mock implements SettingsController {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ActionHandler handler;
  late List<String> logs;

  setUp(() {
    handler = ActionHandler(
      nes: null,
      nesController: _MockNesController(),
      router: _MockRouter(),
      romManager: _MockRomManager(),
      settingsController: _MockSettingsController(),
      actionStream: const Stream.empty(),
    );

    logs = [];

    final original = debugPrint;

    debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');

    addTearDown(() {
      debugPrint = original;
      handler.dispose();
    });
  });

  InputActionEvent press(InputAction action) => InputActionEvent(
    action: action,
    value: 1.0,
    bindingType: BindingType.hold,
  );

  test('logs an in-game action dropped outside the emulator route', () {
    // The handler starts on MainRoute, so this press is not `_inGame`.
    handler.handleAction(press(controller1A));

    expect(logs, hasLength(1));
    expect(logs.single, contains('dropped in-game action'));
    expect(logs.single, contains('controller1.a'));
    expect(logs.single, contains('MainRoute'));
  });

  test('logs every in-game action type dropped outside the emulator', () {
    for (final action in [controller1A, saveState1, fastForward, reset]) {
      handler.handleAction(press(action));
    }

    expect(logs, hasLength(4));
  });
}
