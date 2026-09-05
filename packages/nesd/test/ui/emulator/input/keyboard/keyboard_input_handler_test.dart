import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/input/keyboard/keyboard_input_handler.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';

void main() {
  late KeyboardInputHandler handler;
  late List<InputActionEvent> events;

  setUp(() {
    events = [];

    final stream = ActionStream()..stream.listen(events.add);

    handler = KeyboardInputHandler(
      bindings: [
        Binding(
          index: 0,
          action: inputLeft,
          input: InputCombination.keyboard({LogicalKeyboardKey.arrowLeft}),
        ),
      ],
      actionStream: stream,
    );

    addTearDown(stream.dispose);
  });

  Future<void> pumpFocused(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            handler.handleKeyEvent(event);

            return KeyEventResult.handled;
          },
          child: const SizedBox(),
        ),
      ),
    );

    await tester.pump();
  }

  testWidgets('a key repeat is swallowed while no session is open', (
    tester,
  ) async {
    await pumpFocused(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    events.clear();

    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowLeft);

    expect(events, isEmpty);
  });

  testWidgets('a key repeat re-fires the held action while scrubbing', (
    tester,
  ) async {
    handler.scrubOpen = true;

    await pumpFocused(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    events.clear();

    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowLeft);

    expect(events, hasLength(2));
    expect(events.every((e) => e.action == inputLeft), isTrue);
    expect(events.every((e) => e.value == 1.0), isTrue);
  });
}
