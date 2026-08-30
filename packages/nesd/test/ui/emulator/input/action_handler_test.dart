import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart' hide reset;
import 'package:nesd/log/log.dart';
import 'package:nesd/log/log_sink.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/emulator/tools/emulator_tools_controller.dart';
import 'package:nesd/ui/emulator/tools/tool_focus_controller.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/settings.dart';

class _MockNesController extends Mock implements NesController {}

class _MockRouter extends Mock implements Router {}

class _MockRomManager extends Mock implements RomManager {}

class _MockSettingsController extends Mock implements SettingsController {}

class _MockEmulatorToolsController extends Mock
    implements EmulatorToolsController {}

class _MockToolFocusController extends Mock implements ToolFocusController {}

class _RecordingSink extends LogSink {
  _RecordingSink(this.records);

  final List<LogRecord> records;

  @override
  void add(LogRecord record) => records.add(record);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ActionHandler handler;
  late _MockEmulatorToolsController toolsController;
  late List<LogRecord> logged;

  setUp(() {
    toolsController = _MockEmulatorToolsController();

    handler = ActionHandler(
      nes: null,
      nesController: _MockNesController(),
      router: _MockRouter(),
      romManager: _MockRomManager(),
      settingsController: _MockSettingsController(),
      toolsController: toolsController,
      toolFocusController: _MockToolFocusController(),
      actionStream: const Stream.empty(),
    );

    logged = [];

    NesdLog.install(
      NesdLog(sinks: [_RecordingSink(logged)], minimumLevel: LogLevel.debug),
    );

    addTearDown(() async {
      handler.dispose();

      await NesdLog.instance.close();

      NesdLog.install(NesdLog());
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

    expect(logged, hasLength(1));
    expect(logged.single.message, contains('dropped in-game action'));
    expect(logged.single.message, contains('controller1.a'));
    expect(logged.single.message, contains('not the active screen'));
  });

  test('logs every in-game action type dropped outside the emulator', () {
    for (final action in [controller1A, saveState1, fastForward, reset]) {
      handler.handleAction(press(action));
    }

    expect(logged, hasLength(4));
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
    expect(logged, isEmpty);
  });
}
