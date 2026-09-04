import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/emulator/display.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/overscan_crop.dart';
import 'package:nesd/ui/emulator/rewind/rewind_scrub_controller.dart';
import 'package:nesd/ui/emulator/rewind/rewind_timeline_overlay.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter_registry.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../robot.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences {}

Future<ui.Image> _solidImage() {
  final completer = Completer<ui.Image>();

  ui.decodeImageFromPixels(
    Uint8List.fromList(List.filled(4 * 4 * 4, 0xff)),
    4,
    4,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );

  return completer.future;
}

RewindScrubState _stateWith(ui.Image thumbnail) => RewindScrubState(
  open: true,
  cursorSequence: 0,
  oldestSequence: 0,
  newestSequence: 60,
  captureInterval: 1,
  frameRate: 60,
  thumbnails: [thumbnail],
  thumbnailSequences: const [0],
  settled: false,
);

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

Future<void> _startGame(
  Robot r, {
  Size logicalSize = const Size(1920, 1080),
}) async {
  await r.pumpApp(logicalSize: logicalSize);
  await r.mainMenu.tapFirstRomTile();

  r.emulator.expectEmulatorWidgetFound();

  await r.waitUntil(
    () => find.byKey(DisplayBuilder.screenKey).evaluate().isNotEmpty,
  );

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

RewindScrubState _scrubState(Robot r) =>
    r.container.read(rewindScrubControllerProvider);

Future<void> _openScrubber(Robot r) async {
  unawaited(r.container.read(rewindScrubControllerProvider.notifier).open());

  await r.waitUntil(() => _scrubState(r).open, maxAttempts: 40);
  await r.tester.pump();

  expect(
    _scrubState(r).thumbnails,
    isNotEmpty,
    reason: 'the preview needs a thumbnail to show',
  );
}

Future<void> _unsettle(Robot r) async {
  r.isolateHandles.last.emit(
    RewindScrubPositionEvent(
      sequence: _scrubState(r).cursorSequence,
      settled: false,
    ),
  );

  await r.tester.pump();
}

Future<void> _settle(Robot r) async {
  r.isolateHandles.last.emit(
    RewindScrubPositionEvent(
      sequence: _scrubState(r).cursorSequence,
      settled: true,
    ),
  );

  await r.tester.pump();
  await r.tester.pump(const Duration(milliseconds: 250));
}

Rect _displayRect(WidgetTester tester) =>
    tester.getRect(find.byKey(DisplayBuilder.screenKey));

Rect _previewRect(WidgetTester tester) =>
    tester.getRect(find.byKey(RewindDragPreview.previewKey));

Matcher _rectCloseTo(Rect rect) => isA<Rect>()
    .having((r) => r.left, 'left', closeTo(rect.left, 0.5))
    .having((r) => r.top, 'top', closeTo(rect.top, 0.5))
    .having((r) => r.width, 'width', closeTo(rect.width, 0.5))
    .having((r) => r.height, 'height', closeTo(rect.height, 0.5));

void main() {
  testWidgets('is absent while the walk is settled', (tester) async {
    final r = _robot(tester);

    await _startGame(r);
    await _openScrubber(r);

    expect(find.byType(RewindDragPreview), findsNothing);

    await _quitGame(r);
  });

  testWidgets('appears while the walk is catching up', (tester) async {
    final r = _robot(tester);

    await _startGame(r);
    await _openScrubber(r);
    await _unsettle(r);

    expect(find.byType(RewindDragPreview), findsOneWidget);

    await _quitGame(r);
  });

  testWidgets('runs through the same video filters as the display', (
    tester,
  ) async {
    late ui.FragmentProgram program;
    late ui.Image thumbnail;

    await tester.runAsync(() async {
      program = await ui.FragmentProgram.fromAsset('shaders/crt.frag');
      thumbnail = await _solidImage();
    });

    final prefs = _MockSharedPreferences();

    when(() => prefs.getString(any())).thenReturn('{"videoFilters":["crt"]}');
    when(() => prefs.setString(any(), any())).thenAnswer((_) async => true);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        fragmentProgramLoaderProvider.overrideWithValue((_) async => program),
      ],
    );

    addTearDown(container.dispose);

    container
        .read(videoFilterRegistryProvider.notifier)
        .ensureLoaded(VideoFilter.crt);

    await tester.runAsync(pumpEventQueue);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: RewindDragPreview(
            state: _stateWith(thumbnail),
            shaderFilterSupported: true,
            imageFilterFactory: (_) =>
                ui.ImageFilter.matrix(Matrix4.identity().storage),
          ),
        ),
      ),
    );

    expect(
      find.ancestor(
        of: find.byKey(RewindDragPreview.imageKey),
        matching: find.byType(ImageFiltered),
      ),
      findsOneWidget,
    );
  });

  testWidgets('crops the preview the way the display does', (tester) async {
    final r = _robot(tester);

    await _startGame(r);
    await _openScrubber(r);
    await _unsettle(r);

    expect(
      find.ancestor(
        of: find.byKey(RewindDragPreview.imageKey),
        matching: find.byType(OverscanCrop),
      ),
      findsOneWidget,
    );

    await _quitGame(r);
  });

  testWidgets('is absent again once the walk has settled', (tester) async {
    final r = _robot(tester);

    await _startGame(r);
    await _openScrubber(r);
    await _unsettle(r);

    expect(find.byType(RewindDragPreview), findsOneWidget);

    await _settle(r);

    expect(find.byType(RewindDragPreview), findsNothing);

    await _quitGame(r);
  });

  testWidgets('lands exactly where the live frame does', (tester) async {
    final r = _robot(tester);

    await _startGame(r);
    await _openScrubber(r);
    await _unsettle(r);

    expect(_previewRect(tester), _rectCloseTo(_displayRect(tester)));

    await _quitGame(r);
  });

  testWidgets('follows the display anchor in portrait with touch '
      'controls', (tester) async {
    final r = _robot(tester, showTouchControls: true);

    await _startGame(r, logicalSize: const Size(1080, 1920));
    await _openScrubber(r);
    await _unsettle(r);

    final display = _displayRect(tester);

    expect(_previewRect(tester), _rectCloseTo(display));
    expect(
      display.center.dy,
      lessThan(1920 / 2),
      reason: 'the display was expected to be anchored above centre',
    );

    await _quitGame(r);
  });
}
