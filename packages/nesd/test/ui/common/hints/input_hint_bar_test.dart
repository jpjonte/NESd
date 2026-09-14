import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:nesd/ui/common/hints/input_hint_bar.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_id.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/input/input_hint_resolver.dart';
import 'package:nesd/ui/emulator/input/input_method.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';

Binding _keyboard(InputAction action, Set<LogicalKeyboardKey> keys) =>
    Binding(index: 0, action: action, input: InputCombination.keyboard(keys));

Binding _gamepad(InputAction action, GamepadButton button) => Binding(
  index: 1,
  action: action,
  input: InputCombination.gamepad(
    slot: 0,
    inputs: {gamepadButtonInput(button)},
  ),
);

final _bindings = [
  _keyboard(confirm, {LogicalKeyboardKey.enter}),
  _keyboard(cancel, {LogicalKeyboardKey.escape}),
  _keyboard(openMenu, {LogicalKeyboardKey.keyS, LogicalKeyboardKey.control}),
  _keyboard(inputLeft, {LogicalKeyboardKey.arrowLeft}),
  _keyboard(inputUp, {LogicalKeyboardKey.arrowUp}),
  _keyboard(previousInput, {LogicalKeyboardKey.arrowUp}),
  _gamepad(confirm, GamepadButton.a),
];

Future<void> _pump(
  WidgetTester tester, {
  required List<InputHint> hints,
  InputMethod method = InputMethod.keyboardMouse,
}) async {
  final resolver = InputHintResolver(method: method, bindings: _bindings);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [inputHintResolverProvider.overrideWith((_) => resolver)],
      child: MaterialApp(
        home: Scaffold(
          body: Center(child: InputHintBar(hints: hints)),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders one cap per bound key, modifiers first', (tester) async {
    await _pump(
      tester,
      hints: const [
        InputHint(actions: [openMenu], label: 'Save'),
      ],
    );

    expect(find.text('Ctrl'), findsOneWidget);
    expect(find.text('+'), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Ctrl')).dx,
      lessThan(tester.getTopLeft(find.text('S')).dx),
    );
  });

  testWidgets('shortens arrow and escape key labels', (tester) async {
    await _pump(
      tester,
      hints: const [
        InputHint(actions: [inputLeft], label: 'Left'),
        InputHint(actions: [cancel], label: 'Close'),
      ],
    );

    expect(find.text('←'), findsOneWidget);
    expect(find.text('Esc'), findsOneWidget);
  });

  testWidgets('hides a hint whose actions are unbound', (tester) async {
    await _pump(
      tester,
      hints: const [
        InputHint(actions: [confirm], label: 'Select'),
        InputHint(actions: [nextTab], label: 'Next page'),
      ],
    );

    expect(find.text('Select'), findsOneWidget);
    expect(find.text('Next page'), findsNothing);
  });

  testWidgets('shows a hint without actions as plain text', (tester) async {
    await _pump(tester, hints: const [InputHint(label: 'Drag to scrub')]);

    expect(find.text('Drag to scrub'), findsOneWidget);
  });

  testWidgets('shows alternatives sharing a key once', (tester) async {
    await _pump(
      tester,
      hints: const [
        InputHint(actions: [inputUp, previousInput], label: 'Up'),
      ],
    );

    expect(find.text('↑'), findsOneWidget);
  });

  testWidgets('shows gamepad button labels for the gamepad', (tester) async {
    await _pump(
      tester,
      method: InputMethod.gamepad,
      hints: const [
        InputHint(actions: [confirm], label: 'Select'),
        InputHint(actions: [cancel], label: 'Close'),
      ],
    );

    expect(find.text('A'), findsOneWidget);
    expect(find.text('Enter'), findsNothing);
    expect(find.text('Close'), findsNothing);
  });

  testWidgets('offers tappable hints as finger-sized controls on touch', (
    tester,
  ) async {
    var pressed = 0;

    await _pump(
      tester,
      method: InputMethod.touch,
      hints: [
        const InputHint(actions: [inputLeft], label: 'Step'),
        InputHint(
          actions: const [confirm],
          icon: Icons.play_arrow,
          label: 'Resume',
          onPressed: () => pressed++,
        ),
      ],
    );

    expect(find.text('Step'), findsNothing);
    expect(find.text('Enter'), findsNothing);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(
      tester.getSize(find.byType(InkWell)).height,
      greaterThanOrEqualTo(44),
    );

    await tester.tap(find.text('Resume'));
    await tester.pump();

    expect(pressed, 1);
  });

  testWidgets('renders nothing when no hint applies', (tester) async {
    await _pump(
      tester,
      hints: const [
        InputHint(actions: [nextTab], label: 'Next page'),
      ],
    );

    expect(find.byType(Wrap), findsNothing);
  });

  test('names the meta key per platform', () {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(keyCapLabel(LogicalKeyboardKey.metaLeft), 'Cmd');

    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(keyCapLabel(LogicalKeyboardKey.meta), 'Win');

    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    expect(keyCapLabel(LogicalKeyboardKey.metaRight), 'Meta');
  });
}
