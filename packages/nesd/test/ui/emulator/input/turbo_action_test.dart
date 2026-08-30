import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart' hide reset;
import 'package:nesd/nes/bus.dart';
import 'package:nesd/ui/emulator/input/action/all_actions.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/remote_nes.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/emulator/tools/emulator_tools_controller.dart';
import 'package:nesd/ui/emulator/tools/tool_focus_controller.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/settings.dart';

class _MockNes extends Mock implements RemoteNes {}

class _MockNesController extends Mock implements NesController {}

class _MockRouter extends Mock implements Router {}

class _MockRomManager extends Mock implements RomManager {}

class _MockSettingsController extends Mock implements SettingsController {}

class _MockEmulatorToolsController extends Mock
    implements EmulatorToolsController {}

class _MockToolFocusController extends Mock implements ToolFocusController {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockNes nes;
  late ActionHandler handler;

  setUp(() {
    nes = _MockNes();

    handler = ActionHandler(
      nes: nes,
      nesController: _MockNesController(),
      router: _MockRouter(),
      romManager: _MockRomManager(),
      settingsController: _MockSettingsController(),
      toolsController: _MockEmulatorToolsController(),
      toolFocusController: _MockToolFocusController(),
      actionStream: const Stream.empty(),
    )..emulatorActive = true;

    addTearDown(handler.dispose);
  });

  InputActionEvent event(
    InputAction action, {
    required double value,
    BindingType bindingType = BindingType.hold,
  }) =>
      InputActionEvent(action: action, value: value, bindingType: bindingType);

  group('turbo actions', () {
    test('are bindable alongside the plain controller actions', () {
      expect(
        inputActions,
        containsAll([
          controller1TurboA,
          controller1TurboB,
          controller2TurboA,
          controller2TurboB,
        ]),
      );
    });

    test('resolve from their persisted codes', () {
      expect(
        InputAction.fromCode('controller1.turboA'),
        same(controller1TurboA),
      );
      expect(
        InputAction.fromCode('controller2.turboB'),
        same(controller2TurboB),
      );
    });

    test('press the mapped button with the turbo flag set', () {
      handler.handleAction(event(controller1TurboA, value: 1.0));

      verify(() => nes.buttonDown(0, NesButton.a, turbo: true)).called(1);
    });

    test('release the mapped button with the turbo flag set', () {
      handler.handleAction(event(controller2TurboB, value: 0.0));

      verify(() => nes.buttonUp(1, NesButton.b, turbo: true)).called(1);
    });

    test('toggle the mapped button when bound as a toggle', () {
      handler.handleAction(
        event(controller1TurboB, value: 1.0, bindingType: BindingType.toggle),
      );

      verify(() => nes.buttonToggle(0, NesButton.b, turbo: true)).called(1);
    });

    test('leave plain controller presses untouched by turbo', () {
      handler.handleAction(event(controller1A, value: 1.0));

      verify(() => nes.buttonDown(0, NesButton.a)).called(1);
    });
  });
}
