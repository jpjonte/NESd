import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart' hide reset;
import 'package:nesd/ui/emulator/input/action/all_actions.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/remote_nes.dart';
import 'package:nesd/ui/emulator/rewind/rewind_scrub_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/emulator/screenshot/screenshot_controller.dart';
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

class _MockRewindScrubController extends Mock
    implements RewindScrubController {}

class _MockScreenshotController extends Mock implements ScreenshotController {}

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
      scrubController: _MockRewindScrubController(),
      screenshotController: _MockScreenshotController(),
      actionStream: const Stream.empty(),
    )..emulatorActive = true;

    addTearDown(handler.dispose);
  });

  InputActionEvent event({required double value}) => InputActionEvent(
    action: nextFrame,
    value: value,
    bindingType: BindingType.hold,
  );

  test('is a bindable, non-toggleable emulator action', () {
    expect(emulatorActions, contains(nextFrame));
    expect(nextFrame.title, 'Next Frame');
    expect(nextFrame.toggleable, isFalse);
    expect(isInGameAction(nextFrame), isTrue);
  });

  test('resolves from its persisted code', () {
    expect(InputAction.fromCode('state.nextFrame'), same(nextFrame));
  });

  test('a press in game advances a frame', () {
    handler.handleAction(event(value: 1));

    verify(() => nes.nextFrame()).called(1);
  });

  test('every repeated press advances again', () {
    handler
      ..handleAction(event(value: 1))
      ..handleAction(event(value: 1))
      ..handleAction(event(value: 1));

    verify(() => nes.nextFrame()).called(3);
  });

  test('a release does nothing', () {
    handler.handleAction(event(value: 0));

    verifyNever(() => nes.nextFrame());
  });

  test('is swallowed while the rewind timeline is open', () {
    handler
      ..scrubState = const RewindScrubState(
        open: true,
        cursorSequence: 0,
        oldestSequence: 0,
        newestSequence: 0,
        captureInterval: 1,
        frameRate: 60,
        thumbnails: [],
        thumbnailSequences: [],
        settled: true,
      )
      ..handleAction(event(value: 1));

    verifyNever(() => nes.nextFrame());
  });

  test('is dropped while the tool panel has focus', () {
    handler
      ..toolsFocused = true
      ..handleAction(event(value: 1));

    verifyNever(() => nes.nextFrame());
  });

  test('does nothing outside the emulator', () {
    handler
      ..emulatorActive = false
      ..handleAction(event(value: 1));

    verifyNever(() => nes.nextFrame());
  });
}
