import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_directory.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_mapper.dart';
import 'package:nesd/ui/emulator/input/input_method.dart';

class _Tracker {
  _Tracker._(this._tester, this._events, this._container);

  static Future<_Tracker> start(
    WidgetTester tester,
    TargetPlatform platform,
  ) async {
    final events = StreamController<GamepadEvent>();

    final mapper = GamepadInputMapper(
      events: events.stream,
      directory: GamepadDeviceDirectory(lookup: () async => {}),
    );

    final container = ProviderContainer(
      overrides: [gamepadInputMapperProvider.overrideWith((_) => mapper)],
    );

    addTearDown(() {
      container.dispose();
      mapper.dispose();
      events.close();
    });

    await tester.pumpWidget(const SizedBox.expand());

    debugDefaultTargetPlatformOverride = platform;

    final tracker = _Tracker._(tester, events, container)..recent;

    debugDefaultTargetPlatformOverride = null;

    return tracker;
  }

  final WidgetTester _tester;
  final StreamController<GamepadEvent> _events;
  final ProviderContainer _container;

  RecentInput get recent => _container.read(recentInputMethodProvider);

  Future<void> pressGamepad(String gamepadId, {double value = 1.0}) async {
    _events.add(
      GamepadEvent(
        gamepadId: gamepadId,
        timestamp: 0,
        type: KeyType.button,
        key: 'button_0',
        value: value,
      ),
    );

    await _tester.pump();
  }

  Future<void> pressKey(LogicalKeyboardKey key) async {
    await simulateKeyDownEvent(key);
    await simulateKeyUpEvent(key);
  }

  Future<TestGesture> mouse() async {
    final gesture = await _tester.createGesture(kind: PointerDeviceKind.mouse);

    await gesture.addPointer(location: const Offset(10, 10));

    return gesture;
  }
}

void main() {
  testWidgets('starts on touch on mobile platforms', (tester) async {
    final tracker = await _Tracker.start(tester, TargetPlatform.android);

    expect(tracker.recent.method, InputMethod.touch);
  });

  testWidgets('starts on keyboard and mouse on desktop', (tester) async {
    final tracker = await _Tracker.start(tester, TargetPlatform.macOS);

    expect(tracker.recent.method, InputMethod.keyboardMouse);
  });

  testWidgets('a key press switches to keyboard and mouse', (tester) async {
    final tracker = await _Tracker.start(tester, TargetPlatform.android);

    await tracker.pressKey(LogicalKeyboardKey.keyA);

    expect(tracker.recent.method, InputMethod.keyboardMouse);
  });

  testWidgets('a touch switches to touch', (tester) async {
    final tracker = await _Tracker.start(tester, TargetPlatform.macOS);

    final finger = await tester.startGesture(const Offset(10, 10));
    await finger.up();

    expect(tracker.recent.method, InputMethod.touch);
  });

  testWidgets('a mouse click switches to keyboard and mouse', (tester) async {
    final tracker = await _Tracker.start(tester, TargetPlatform.android);

    final mouse = await tracker.mouse();
    await mouse.down(const Offset(10, 10));
    await mouse.up();

    expect(tracker.recent.method, InputMethod.keyboardMouse);
  });

  testWidgets('a gamepad press switches to that gamepad', (tester) async {
    final tracker = await _Tracker.start(tester, TargetPlatform.macOS);

    await tracker.pressGamepad('pad-1');

    expect(tracker.recent.method, InputMethod.gamepad);
    expect(tracker.recent.gamepadId, 'pad-1');
  });

  testWidgets('gamepad input below the press threshold does not switch', (
    tester,
  ) async {
    final tracker = await _Tracker.start(tester, TargetPlatform.macOS);

    await tracker.pressGamepad('pad-1', value: 0.1);

    expect(tracker.recent.method, InputMethod.keyboardMouse);
  });

  testWidgets('a nudged mouse does not switch away from the gamepad', (
    tester,
  ) async {
    final tracker = await _Tracker.start(tester, TargetPlatform.macOS);
    await tracker.pressGamepad('pad-1');

    final mouse = await tracker.mouse();
    await mouse.moveBy(const Offset(mouseMoveThreshold / 4, 0));

    expect(tracker.recent.method, InputMethod.gamepad);

    await mouse.moveBy(const Offset(mouseMoveThreshold, 0));

    expect(tracker.recent.method, InputMethod.keyboardMouse);
  });

  testWidgets('mouse travel resets on gamepad input', (tester) async {
    final tracker = await _Tracker.start(tester, TargetPlatform.macOS);
    await tracker.pressGamepad('pad-1');

    final mouse = await tracker.mouse();
    await mouse.moveBy(const Offset(mouseMoveThreshold * 0.75, 0));
    await tracker.pressGamepad('pad-1');
    await mouse.moveBy(const Offset(mouseMoveThreshold * 0.75, 0));

    expect(tracker.recent.method, InputMethod.gamepad);
  });

  testWidgets('keeps the last gamepad across a key press', (tester) async {
    final tracker = await _Tracker.start(tester, TargetPlatform.macOS);
    await tracker.pressGamepad('pad-2');

    await tracker.pressKey(LogicalKeyboardKey.keyA);

    expect(tracker.recent.method, InputMethod.keyboardMouse);
    expect(tracker.recent.gamepadId, 'pad-2');
  });
}
