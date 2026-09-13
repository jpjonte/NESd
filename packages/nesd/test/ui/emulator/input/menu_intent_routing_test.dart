import 'package:flutter/material.dart' hide Router;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rewind/rewind_scrub_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
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

class _MockRewindScrubController extends Mock
    implements RewindScrubController {}

void main() {
  late ActionHandler handler;
  late _MockToolFocusController toolFocus;
  late _MockRouter router;
  late List<Intent> received;

  setUpAll(() {
    registerFallbackValue(const MenuRoute());
  });

  setUp(() {
    toolFocus = _MockToolFocusController();
    router = _MockRouter();
    received = [];

    when(() => router.navigate(any())).thenAnswer((_) async {});
    when(() => toolFocus.exit()).thenReturn(null);

    handler = ActionHandler(
      nes: null,
      nesController: _MockNesController(),
      router: router,
      romManager: _MockRomManager(),
      settingsController: _MockSettingsController(),
      toolsController: _MockEmulatorToolsController(),
      toolFocusController: toolFocus,
      scrubController: _MockRewindScrubController(),
      actionStream: const Stream.empty(),
    )..emulatorActive = false;

    addTearDown(handler.dispose);
  });

  void press(InputAction action) => handler.handleAction(
    InputActionEvent(action: action, value: 1, bindingType: BindingType.hold),
  );

  CallbackAction<T> record<T extends Intent>() =>
      CallbackAction<T>(onInvoke: (intent) => received.add(intent));

  Future<void> pumpFocused(
    WidgetTester tester,
    Map<Type, Action<Intent>> actions,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Actions(
          actions: actions,
          child: const Focus(autofocus: true, child: SizedBox()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('up and down send directional intents that enter text fields', (
    tester,
  ) async {
    await pumpFocused(tester, {
      DirectionalFocusIntent: record<DirectionalFocusIntent>(),
    });

    press(previousInput);
    await tester.pump();
    press(nextInput);
    await tester.pump();
    press(inputUp);
    await tester.pump();
    press(inputDown);

    final directions = received
        .cast<DirectionalFocusIntent>()
        .map((i) => i.direction)
        .toList();

    expect(directions, [
      TraversalDirection.up,
      TraversalDirection.down,
      TraversalDirection.up,
      TraversalDirection.down,
    ]);
    expect(
      received.cast<DirectionalFocusIntent>().every((i) => !i.ignoreTextFields),
      isTrue,
    );
  });

  testWidgets('left adjusts when the focus handles decrease', (tester) async {
    await pumpFocused(tester, {
      DecreaseIntent: record<DecreaseIntent>(),
      IncreaseIntent: record<IncreaseIntent>(),
      DirectionalFocusIntent: record<DirectionalFocusIntent>(),
    });

    press(inputLeft);
    await tester.pump();
    press(inputRight);

    expect(received, [isA<DecreaseIntent>(), isA<IncreaseIntent>()]);
  });

  testWidgets('left moves focus when nothing handles decrease', (tester) async {
    await pumpFocused(tester, {
      DirectionalFocusIntent: record<DirectionalFocusIntent>(),
    });

    press(inputLeft);
    await tester.pump();
    press(inputRight);

    expect(received.cast<DirectionalFocusIntent>().map((i) => i.direction), [
      TraversalDirection.left,
      TraversalDirection.right,
    ]);
  });

  testWidgets('menu decrease never falls through to a focus move', (
    tester,
  ) async {
    await pumpFocused(tester, {
      DirectionalFocusIntent: record<DirectionalFocusIntent>(),
    });

    press(menuDecrease);
    press(menuIncrease);

    expect(received, isEmpty);
  });

  testWidgets('one press moves once even when two actions fire', (
    tester,
  ) async {
    await pumpFocused(tester, {
      DirectionalFocusIntent: record<DirectionalFocusIntent>(),
    });

    press(previousInput);
    press(inputUp);

    expect(received, hasLength(1));

    await tester.pump();

    press(previousInput);

    expect(received, hasLength(2));
  });

  testWidgets('open menu goes back one level in a menu', (tester) async {
    await pumpFocused(tester, {DismissIntent: record<DismissIntent>()});

    press(openMenu);

    expect(received, [isA<DismissIntent>()]);
  });

  testWidgets(
    'tab falls through to reading-order focus when nothing handles it',
    (tester) async {
      await pumpFocused(tester, {
        NextFocusIntent: record<NextFocusIntent>(),
        PreviousFocusIntent: record<PreviousFocusIntent>(),
      });

      press(nextTab);
      await tester.pump();
      press(previousTab);

      expect(received, [isA<NextFocusIntent>(), isA<PreviousFocusIntent>()]);
    },
  );

  testWidgets('tab prefers a tab handler', (tester) async {
    await pumpFocused(tester, {
      NextTabIntent: record<NextTabIntent>(),
      NextFocusIntent: record<NextFocusIntent>(),
    });

    press(nextTab);

    expect(received, [isA<NextTabIntent>()]);
  });

  testWidgets('open menu leaves a focused tool panel', (tester) async {
    handler
      ..emulatorActive = true
      ..toolsFocused = true;

    await pumpFocused(tester, {DismissIntent: record<DismissIntent>()});

    press(openMenu);

    verify(() => toolFocus.exit()).called(1);
    verifyNever(() => router.navigate(any()));
    expect(received, isEmpty);
  });
}
