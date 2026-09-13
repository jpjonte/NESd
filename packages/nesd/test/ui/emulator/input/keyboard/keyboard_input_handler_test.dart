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

  KeyboardInputHandler handlerWith(List<Binding> bindings) {
    final stream = ActionStream()..stream.listen(events.add);

    addTearDown(stream.dispose);

    return KeyboardInputHandler(bindings: bindings, actionStream: stream);
  }

  Binding key(InputAction action, LogicalKeyboardKey k) =>
      Binding(index: 0, action: action, input: InputCombination.keyboard({k}));

  Future<bool Function()> pumpTextField(
    WidgetTester tester,
    KeyboardInputHandler h,
  ) async {
    KeyEventResult? last;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Focus(
            onKeyEvent: (node, event) {
              last = h.handleKeyEvent(event)
                  ? KeyEventResult.handled
                  : KeyEventResult.ignored;

              return last!;
            },
            child: const TextField(autofocus: true),
          ),
        ),
      ),
    );
    await tester.pump();

    return () => last == KeyEventResult.handled;
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

  testWidgets('in a menu a key repeat re-fires a navigation action', (
    tester,
  ) async {
    handler.menuMode = true;

    await pumpFocused(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    events.clear();

    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowLeft);

    expect(events, hasLength(1));
    expect(events.single.action, inputLeft);
  });

  testWidgets('in a menu a key repeat of a non-navigation action is dropped', (
    tester,
  ) async {
    final h = handlerWith([key(confirm, LogicalKeyboardKey.enter)])
      ..menuMode = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            h.handleKeyEvent(event);

            return KeyEventResult.handled;
          },
          child: const SizedBox(),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    events.clear();

    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);

    expect(events, isEmpty);
  });

  testWidgets('handleKeyEvent reports whether a binding consumed the key', (
    tester,
  ) async {
    final h = handlerWith([key(inputLeft, LogicalKeyboardKey.arrowLeft)]);
    late bool consumed;

    await tester.pumpWidget(
      MaterialApp(
        home: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            consumed = h.handleKeyEvent(event);

            return KeyEventResult.handled;
          },
          child: const SizedBox(),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    expect(consumed, isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyQ);
    expect(consumed, isFalse);
  });

  testWidgets('a text field keeps its editing keys but not navigation', (
    tester,
  ) async {
    final h = handlerWith([
      key(cancel, LogicalKeyboardKey.backspace),
      key(inputLeft, LogicalKeyboardKey.arrowLeft),
      key(nextInput, LogicalKeyboardKey.arrowDown),
      key(confirm, LogicalKeyboardKey.enter),
      key(openMenu, LogicalKeyboardKey.escape),
    ])..menuMode = true;

    final handled = await pumpTextField(tester, h);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.backspace);
    expect(events, isEmpty, reason: 'backspace belongs to the editor');
    expect(handled(), isFalse);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    expect(events, isEmpty, reason: 'left moves the caret');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    expect(events.map((e) => e.action), [nextInput]);
    expect(handled(), isTrue);

    events.clear();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    expect(events.map((e) => e.action), [confirm]);

    events.clear();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    expect(events.map((e) => e.action), [openMenu]);
  });

  testWidgets('the text field rule also applies in game', (tester) async {
    final h = handlerWith([key(cancel, LogicalKeyboardKey.backspace)]);

    await pumpTextField(tester, h);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.backspace);

    expect(events, isEmpty);
  });

  testWidgets('a held editing key never repeats into a menu action', (
    tester,
  ) async {
    final h = handlerWith([
      key(inputLeft, LogicalKeyboardKey.arrowLeft),
      key(nextInput, LogicalKeyboardKey.arrowDown),
    ])..menuMode = true;

    await pumpTextField(tester, h);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowLeft);
    expect(events, isEmpty, reason: 'left belongs to the caret, held or not');

    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    events.clear();

    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowDown);
    expect(events.map((e) => e.action), [nextInput]);
  });

  testWidgets('in a menu, keys bound only to in-game actions fall through', (
    tester,
  ) async {
    final h = handlerWith([key(controller1A, LogicalKeyboardKey.keyZ)])
      ..menuMode = true;
    late bool consumed;

    await tester.pumpWidget(
      MaterialApp(
        home: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            consumed = h.handleKeyEvent(event);

            return KeyEventResult.handled;
          },
          child: const SizedBox(),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);

    expect(events, isEmpty);
    expect(consumed, isFalse);

    h.menuMode = false;
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);

    expect(events.map((e) => e.action), [controller1A]);
  });

  Future<void> pumpHandler(WidgetTester tester, KeyboardInputHandler h) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            h.handleKeyEvent(event);

            return KeyEventResult.handled;
          },
          child: const SizedBox(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('in a menu a bare modifier binding fires on release', (
    tester,
  ) async {
    final h = handlerWith([key(secondaryAction, LogicalKeyboardKey.shift)])
      ..menuMode = true;

    await pumpHandler(tester, h);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    expect(events, isEmpty);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    expect(events.map((e) => (e.action, e.value)), [
      (secondaryAction, 1.0),
      (secondaryAction, 0.0),
    ]);
  });

  testWidgets(
    'in a menu a modifier that completed a chord does not fire on its own',
    (tester) async {
      final h = handlerWith([
        key(secondaryAction, LogicalKeyboardKey.shift),
        Binding(
          index: 0,
          action: previousTab,
          input: InputCombination.keyboard({
            LogicalKeyboardKey.shift,
            LogicalKeyboardKey.tab,
          }),
        ),
      ])..menuMode = true;

      await pumpHandler(tester, h);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      expect(events, isEmpty);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
      expect(events.map((e) => (e.action, e.value)), [(previousTab, 1.0)]);

      events.clear();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
      expect(events.map((e) => (e.action, e.value)), [(previousTab, 0.0)]);

      events.clear();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      expect(events, isEmpty);
    },
  );

  testWidgets('in game a bare modifier binding still fires on press', (
    tester,
  ) async {
    final h = handlerWith([
      key(secondaryAction, LogicalKeyboardKey.shift),
      Binding(
        index: 0,
        action: previousTab,
        input: InputCombination.keyboard({
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.tab,
        }),
      ),
    ]);

    await pumpHandler(tester, h);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);

    expect(events.map((e) => (e.action, e.value)), [(secondaryAction, 1.0)]);
  });

  testWidgets('a pending modifier survives the release of an unrelated key', (
    tester,
  ) async {
    final h = handlerWith([key(secondaryAction, LogicalKeyboardKey.shift)])
      ..menuMode = true;

    await pumpHandler(tester, h);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    expect(events, isEmpty);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyQ);
    expect(events, isEmpty);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyQ);
    expect(events, isEmpty);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    expect(events.map((e) => (e.action, e.value)), [
      (secondaryAction, 1.0),
      (secondaryAction, 0.0),
    ]);
  });

  testWidgets('a second held modifier does not release a pending one', (
    tester,
  ) async {
    final h = handlerWith([key(secondaryAction, LogicalKeyboardKey.shift)])
      ..menuMode = true;

    await pumpHandler(tester, h);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    expect(events, isEmpty);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    expect(events, isEmpty);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    expect(events, isEmpty);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    expect(events.map((e) => (e.action, e.value)), [
      (secondaryAction, 1.0),
      (secondaryAction, 0.0),
    ]);
  });

  testWidgets('a modifier-only classification uses the matched keys', (
    tester,
  ) async {
    final h = handlerWith([
      key(secondaryAction, LogicalKeyboardKey.shift),
      key(secondaryAction, LogicalKeyboardKey.keyQ),
    ])..menuMode = true;

    await pumpHandler(tester, h);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyQ);
    expect(events.map((e) => (e.action, e.value)), [(secondaryAction, 1.0)]);

    events.clear();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyQ);
    expect(events.map((e) => (e.action, e.value)), [(secondaryAction, 0.0)]);
  });
}
