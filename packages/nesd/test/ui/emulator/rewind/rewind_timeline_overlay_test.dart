import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/emulator/emulator_active.dart';
import 'package:nesd/ui/emulator/emulator_widget.dart';
import 'package:nesd/ui/emulator/input/touch/touch_controls.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rewind/rewind_scrub_controller.dart';
import 'package:nesd/ui/emulator/rewind/rewind_timeline_overlay.dart';
import 'package:nesd/ui/toast/toaster.dart';

import '../../robot.dart';

Robot _robot(WidgetTester tester, {bool showTouchControls = false}) =>
    Robot(tester)..initSettings({
      'showTouchControls': showTouchControls,
      'recentRoms': [
        {
          'file': {
            'path': '/test/roms/nestest.nes',
            'name': '/test/roms/nestest.nes',
            'type': 'file',
          },
        },
      ],
    });

Future<void> _startGame(Robot r) async {
  await r.pumpApp();
  await r.mainMenu.tapFirstRomTile();

  r.emulator.expectEmulatorWidgetFound();

  await r.pumpFrames(const Duration(seconds: 2));
}

Future<void> _quitGame(Robot r) async {
  if (_scrubState(r).open) {
    r.container.read(rewindScrubControllerProvider.notifier).cancel();

    await r.tester.pump();
  }

  await r.emulator.tapMenu();
  await r.menuScreen.tapQuitGame();
  await r.waitUntil(() => r.container.read(nesStateProvider) == null);
}

Iterable<String> _toastMessages(Robot r) =>
    r.container.read(toastStateProvider).map((toast) => toast.message);

RewindScrubState _scrubState(Robot r) =>
    r.container.read(rewindScrubControllerProvider);

Future<void> _openScrubber(Robot r) async {
  unawaited(r.container.read(rewindScrubControllerProvider.notifier).open());

  await r.waitUntil(() => _scrubState(r).open, maxAttempts: 40);
  await r.tester.pump();

  expect(
    _scrubState(r).newestSequence - _scrubState(r).oldestSequence,
    greaterThan(0),
    reason: 'the session needs a span for the drag to move within',
  );
}

void main() {
  testWidgets('stays out of the tree while no session is open', (tester) async {
    final r = _robot(tester);

    await _startGame(r);

    expect(find.byType(RewindTimelineOverlay), findsNothing);
    expect(find.byType(RewindFilmstrip), findsNothing);

    await _quitGame(r);
  });

  testWidgets('shows the filmstrip and the cursor time when open', (
    tester,
  ) async {
    final r = _robot(tester);

    await _startGame(r);
    await _openScrubber(r);

    expect(find.byType(RewindTimelineOverlay), findsOneWidget);
    expect(find.byType(RewindFilmstrip), findsOneWidget);
    expect(find.text('-0.0s'), findsOneWidget);

    await _quitGame(r);
  });

  testWidgets('hides the touch controls and the menu button while open', (
    tester,
  ) async {
    final r = _robot(tester, showTouchControls: true);

    await _startGame(r);

    expect(find.byType(TouchControlsBuilder), findsOneWidget);
    expect(find.byKey(EmulatorWidget.menuKey), findsOneWidget);

    await _openScrubber(r);

    expect(find.byType(TouchControlsBuilder), findsNothing);
    expect(find.byKey(EmulatorWidget.menuKey), findsNothing);

    await _quitGame(r);
  });

  testWidgets('shows drag and tap hints when touch controls are on', (
    tester,
  ) async {
    final r = _robot(tester, showTouchControls: true);

    await _startGame(r);
    await _openScrubber(r);

    expect(
      find.text('Drag the strip to scrub · Tap a frame to jump there'),
      findsOneWidget,
    );
    expect(find.text('Confirm'), findsNothing);

    await _quitGame(r);
  });

  testWidgets('shows key hints when touch controls are off', (tester) async {
    final r = _robot(tester);

    await _startGame(r);
    await _openScrubber(r);

    expect(find.text('Confirm'), findsOneWidget);
    expect(find.textContaining('Drag'), findsNothing);

    await _quitGame(r);
  });

  testWidgets('covers the emulator surface', (tester) async {
    final r = _robot(tester);

    await _startGame(r);
    await _openScrubber(r);

    expect(
      tester.getRect(find.byType(RewindTimelineOverlay)),
      const Rect.fromLTWH(0, 0, 1920, 1080),
    );

    final strip = tester.getRect(find.byType(RewindFilmstrip));

    expect(strip.left, 0);
    expect(strip.right, 1920);
    expect(strip.bottom, 1080);
    expect(strip.height, greaterThan(0));

    await _quitGame(r);
  });

  testWidgets('dragging the film right walks the cursor back', (tester) async {
    final r = _robot(tester);

    await _startGame(r);
    await _openScrubber(r);

    final before = _scrubState(r).cursorSequence;

    await tester.drag(find.byType(RewindFilmstrip), const Offset(200, 0));
    await tester.pump();

    expect(_scrubState(r).cursorSequence, lessThan(before));
    expect(find.text('-0.0s'), findsNothing);

    await _quitGame(r);
  });

  testWidgets('touching the strip does not move the cursor', (tester) async {
    final r = _robot(tester);

    await _startGame(r);
    await _openScrubber(r);

    final before = _scrubState(r).cursorSequence;

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(RewindFilmstrip)),
    );

    await tester.pump();

    expect(_scrubState(r).cursorSequence, before);

    await gesture.up();
    await tester.pump();

    await _quitGame(r);
  });

  testWidgets('the emulator keeps running behind the overlay', (tester) async {
    final r = _robot(tester);

    await _startGame(r);

    var positions = 0;

    final subscription = r.isolateHandles.last.events.listen((event) {
      if (event is RewindScrubPositionEvent) {
        positions++;
      }
    });

    addTearDown(subscription.cancel);

    await _openScrubber(r);

    positions = 0;

    await r.pumpFrames(const Duration(milliseconds: 500));

    expect(positions, greaterThan(0));
    expect(find.byType(RewindFilmstrip), findsOneWidget);
    expect(r.container.read(emulatorActiveProvider), isTrue);
    expect(r.container.read(nesStateProvider)!.running, isTrue);
    expect(r.container.read(nesStateProvider)!.scrubbing, isTrue);

    await _quitGame(r);
  });

  testWidgets('the auto-save timer does not close an open session', (
    tester,
  ) async {
    final r = _robot(tester);

    await _startGame(r);
    await _openScrubber(r);

    await tester.pump(const Duration(minutes: 1));

    expect(r.container.read(nesStateProvider)!.scrubbing, isTrue);
    expect(_scrubState(r).open, isTrue);
    expect(_toastMessages(r), isNot(contains('Saved state to slot 0')));

    await _quitGame(r);
  });

  testWidgets('closing the session brings the auto-save timer back', (
    tester,
  ) async {
    final r = _robot(tester);

    await _startGame(r);
    await _openScrubber(r);

    r.container.read(rewindScrubControllerProvider.notifier).cancel();

    await tester.pump();

    await tester.pump(const Duration(minutes: 1));

    await r.waitUntil(
      () => _toastMessages(r).contains('Saved state to slot 0'),
      maxAttempts: 40,
    );

    await _quitGame(r);
  });
}
