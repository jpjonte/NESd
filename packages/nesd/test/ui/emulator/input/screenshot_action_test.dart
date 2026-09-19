import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart' hide reset;
import 'package:nesd/ui/emulator/input/action/all_actions.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rewind/rewind_scrub_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/emulator/screenshot/screenshot_controller.dart';
import 'package:nesd/ui/emulator/tools/emulator_tools_controller.dart';
import 'package:nesd/ui/emulator/tools/tool_focus_controller.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';
import 'package:nesd/ui/settings/settings.dart';

class _MockNesController extends Mock implements NesController {}

class _MockRouter extends Mock implements Router {}

class _MockRomManager extends Mock implements RomManager {}

class _MockSettingsController extends Mock implements SettingsController {}

class _MockEmulatorToolsController extends Mock
    implements EmulatorToolsController {}

class _MockToolFocusController extends Mock implements ToolFocusController {}

class _MockRewindScrubController extends Mock
    implements RewindScrubController {}

class _MockScreenshotController extends Mock implements ScreenshotController {}

void main() {
  test('the screenshot action is registered', () {
    expect(allActions.whereType<ScreenshotAction>(), hasLength(1));
    expect(InputAction.fromCode('state.screenshot'), screenshot);
    expect(isInGameAction(screenshot), isTrue);
  });

  test('defaults to F12', () {
    final binding = defaultBindings.firstWhere((b) => b.action == screenshot);

    expect(binding, defaultScreenshotBinding);
    expect(binding.input, InputCombination.keyboard({LogicalKeyboardKey.f12}));
  });

  test('pressing it in game takes a screenshot', () {
    final screenshotController = _MockScreenshotController();

    when(screenshotController.takeScreenshot).thenAnswer((_) async {});

    final handler = ActionHandler(
      nes: null,
      nesController: _MockNesController(),
      router: _MockRouter(),
      romManager: _MockRomManager(),
      settingsController: _MockSettingsController(),
      toolsController: _MockEmulatorToolsController(),
      toolFocusController: _MockToolFocusController(),
      scrubController: _MockRewindScrubController(),
      screenshotController: screenshotController,
      actionStream: const Stream.empty(),
    )..emulatorActive = true;

    addTearDown(handler.dispose);

    handler.handleAction(
      const InputActionEvent(
        action: screenshot,
        value: 1.0,
        bindingType: BindingType.hold,
      ),
    );

    verify(screenshotController.takeScreenshot).called(1);

    handler.handleAction(
      const InputActionEvent(
        action: screenshot,
        value: 0.0,
        bindingType: BindingType.hold,
      ),
    );

    verifyNoMoreInteractions(screenshotController);
  });
}
