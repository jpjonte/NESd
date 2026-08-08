import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart' hide reset;
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/emulator/tools/emulator_tools_controller.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/settings.dart';

class _MockNesController extends Mock implements NesController {}

class _MockRouter extends Mock implements Router {}

class _MockRomManager extends Mock implements RomManager {}

class _MockSettingsController extends Mock implements SettingsController {}

class _MockEmulatorToolsController extends Mock
    implements EmulatorToolsController {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ActionHandler handler;
  late _MockEmulatorToolsController toolsController;
  late List<String> logs;

  setUp(() {
    toolsController = _MockEmulatorToolsController();

    handler = ActionHandler(
      nes: null,
      nesController: _MockNesController(),
      router: _MockRouter(),
      romManager: _MockRomManager(),
      settingsController: _MockSettingsController(),
      toolsController: toolsController,
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
    // The handler starts with emulatorActive false, so this press is not
    // `_inGame`.
    handler.handleAction(press(controller1A));

    expect(logs, hasLength(1));
    expect(logs.single, contains('dropped in-game action'));
    expect(logs.single, contains('controller1.a'));
    expect(logs.single, contains('not the active screen'));
  });

  test('logs every in-game action type dropped outside the emulator', () {
    for (final action in [controller1A, saveState1, fastForward, reset]) {
      handler.handleAction(press(action));
    }

    expect(logs, hasLength(4));
  });

  test('a tool bound as a toggle-type binding still toggles, once per '
      'press, while in-game', () {
    handler
      ..emulatorActive = true
      ..handleAction(
        const InputActionEvent(
          action: toggleDebugger,
          value: 1.0,
          bindingType: BindingType.toggle,
        ),
      )
      ..handleAction(
        const InputActionEvent(
          action: toggleDebugger,
          value: 0.0,
          bindingType: BindingType.toggle,
        ),
      );

    verify(() => toolsController.toggle(EmulatorTool.debugger)).called(1);
    expect(logs, isEmpty);
  });
}
