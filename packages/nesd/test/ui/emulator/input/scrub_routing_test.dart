import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart' hide reset;
import 'package:nesd/log/log.dart';
import 'package:nesd/log/log_sink.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/remote_nes.dart';
import 'package:nesd/ui/emulator/rewind/rewind_scrub_controller.dart';
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

class _MockRewindScrubController extends Mock
    implements RewindScrubController {}

class _RecordingSink extends LogSink {
  _RecordingSink(this.records);

  final List<LogRecord> records;

  @override
  void add(LogRecord record) => records.add(record);
}

RewindScrubState _openState({int captureInterval = 1}) => RewindScrubState(
  open: true,
  cursorSequence: 0,
  oldestSequence: 0,
  newestSequence: 0,
  captureInterval: captureInterval,
  frameRate: 60,
  thumbnails: const [],
  thumbnailSequences: const [],
  settled: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(NesButton.a);
  });

  late _MockNes nes;
  late _MockRewindScrubController scrub;
  late ActionHandler handler;
  late List<LogRecord> logged;

  setUp(() {
    nes = _MockNes();
    scrub = _MockRewindScrubController();

    when(() => scrub.open()).thenAnswer((_) async => true);

    handler = ActionHandler(
      nes: nes,
      nesController: _MockNesController(),
      router: _MockRouter(),
      romManager: _MockRomManager(),
      settingsController: _MockSettingsController(),
      toolsController: _MockEmulatorToolsController(),
      toolFocusController: _MockToolFocusController(),
      scrubController: scrub,
      actionStream: const Stream.empty(),
    )..emulatorActive = true;

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

  void press(InputAction action) => handler.handleAction(
    InputActionEvent(action: action, value: 1.0, bindingType: BindingType.hold),
  );

  void release(InputAction action) => handler.handleAction(
    InputActionEvent(action: action, value: 0.0, bindingType: BindingType.hold),
  );

  test('the timeline action opens the scrubber', () {
    press(rewindTimeline);

    verify(() => scrub.open()).called(1);
  });

  test('the timeline action unpauses before opening the scrubber', () {
    press(rewindTimeline);

    verify(() => nes.unpause()).called(1);
  });

  test('a repeat of the opening press does not close the timeline', () {
    press(rewindTimeline);

    handler.scrubState = _openState();

    press(rewindTimeline);

    verifyNever(() => scrub.cancel());

    release(rewindTimeline);
    press(rewindTimeline);

    verify(() => scrub.cancel()).called(1);
  });

  test('the timeline action is an in-game action dropped outside the '
      'emulator', () {
    handler.emulatorActive = false;

    press(rewindTimeline);

    verifyNever(() => scrub.open());
    expect(logged, hasLength(1));
    expect(logged.single.message, contains('dropped in-game action'));
  });

  test('pressing the timeline action again cancels an open session', () {
    handler.scrubState = _openState();

    press(rewindTimeline);

    verify(() => scrub.cancel()).called(1);
    verifyNever(() => scrub.open());
  });

  test('left and right move a second, up and down a single capture', () {
    handler.scrubState = _openState();

    press(inputLeft);
    press(inputRight);
    press(inputUp);
    press(inputDown);

    final moves = verify(() => scrub.moveBy(captureAny())).captured;

    expect(moves, [-60, 60, 1, -1]);
  });

  test('the keyboard arrows also nudge a single capture', () {
    handler.scrubState = _openState();

    press(previousInput);
    press(nextInput);

    final moves = verify(() => scrub.moveBy(captureAny())).captured;

    expect(moves, [1, -1]);
  });

  test('confirm commits and cancel cancels', () {
    handler.scrubState = _openState();

    press(confirm);
    press(cancel);

    verify(() => scrub.commit()).called(1);
    verify(() => scrub.cancel()).called(1);
  });

  test('game input does not reach the emulator while scrubbing', () {
    handler.scrubState = _openState();

    press(controller1A);

    verifyNever(() => nes.buttonDown(any(), any(), turbo: any(named: 'turbo')));
  });

  test('a toggle-bound press does not reach the emulator while '
      'scrubbing', () {
    handler
      ..scrubState = _openState()
      ..handleAction(
        const InputActionEvent(
          action: controller1A,
          value: 1.0,
          bindingType: BindingType.toggle,
        ),
      );

    verifyNever(
      () => nes.buttonToggle(any(), any(), turbo: any(named: 'turbo')),
    );
  });

  test('holding left accelerates to four seconds', () {
    handler.scrubState = _openState();

    for (var i = 0; i < 40; i++) {
      press(inputLeft);
    }

    final moves = verify(() => scrub.moveBy(captureAny())).captured;

    expect(moves.last, -240);
  });

  test('acceleration resets when interrupted by another scrub action', () {
    handler.scrubState = _openState();

    for (var i = 0; i < 40; i++) {
      press(inputLeft);
    }

    press(inputUp);
    press(inputLeft);

    final moves = verify(() => scrub.moveBy(captureAny())).captured;

    expect(moves.last, -60);
  });

  test('acceleration resets across a session boundary', () {
    handler.scrubState = _openState();

    for (var i = 0; i < 40; i++) {
      press(inputLeft);
    }

    press(cancel);
    handler.scrubState = const RewindScrubState.closed();

    press(rewindTimeline);
    handler.scrubState = _openState();

    press(inputLeft);

    final moves = verify(() => scrub.moveBy(captureAny())).captured;

    expect(moves.last, -60);
  });
}
