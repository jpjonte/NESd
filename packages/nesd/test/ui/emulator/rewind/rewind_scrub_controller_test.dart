import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/nes/isolate/nes_bytes.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/remote_nes.dart';
import 'package:nesd/ui/emulator/rewind/rewind_scrub_controller.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:nesd/ui/toast/toaster.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRemoteNes extends Mock implements RemoteNes {
  _FakeRemoteNes(this._response);

  final RewindScrubBeganResponse? _response;

  final _events = StreamController<NesIsolateEvent>.broadcast();

  final List<int> scrubToCalls = [];
  int commitCalls = 0;
  int cancelCalls = 0;
  int beginRewindScrubCalls = 0;

  @override
  bool get scrubSettled => _scrubSettled;

  @override
  Stream<NesIsolateEvent> get events => _events.stream;

  @override
  Future<RewindScrubBeganResponse?> beginRewindScrub() async {
    beginRewindScrubCalls++;

    return _response;
  }

  @override
  void scrubTo(int sequence) => scrubToCalls.add(sequence);

  @override
  void commitRewindScrub() => commitCalls++;

  @override
  void cancelRewindScrub() => cancelCalls++;

  void emit(NesIsolateEvent event) {
    if (event is RewindScrubPositionEvent) {
      _scrubSettled = event.settled;
    }

    _events.add(event);
  }

  Future<void> close() => _events.close();
}

class _Harness {
  _Harness(this.container, this.remote);

  final ProviderContainer container;
  final _FakeRemoteNes remote;

  RewindScrubController get controller =>
      container.read(rewindScrubControllerProvider.notifier);

  RewindScrubState get state => container.read(rewindScrubControllerProvider);

  Future<void> dispose() async {
    container.dispose();

    await remote.close();
  }
}

Uint8List _solidPixels(int width, int height, List<int> rgba) {
  final pixels = Uint8List(width * height * 4);

  for (var i = 0; i < pixels.length; i += 4) {
    pixels.setRange(i, i + 4, rgba);
  }

  return pixels;
}

RewindScrubBeganResponse _response({
  required int oldestSequence,
  required int newestSequence,
  int captureInterval = 4,
  int frameRate = 60,
  int thumbnailWidth = 2,
  int thumbnailHeight = 2,
  List<List<int>>? colors,
}) {
  final sequences = [oldestSequence, newestSequence];
  final pixelsPerThumbnail = thumbnailWidth * thumbnailHeight * 4;
  final packed = Uint8List(pixelsPerThumbnail * sequences.length);

  for (var i = 0; i < sequences.length; i++) {
    final color = colors == null ? [i, i, i, 255] : colors[i % colors.length];

    packed.setRange(
      i * pixelsPerThumbnail,
      (i + 1) * pixelsPerThumbnail,
      _solidPixels(thumbnailWidth, thumbnailHeight, color),
    );
  }

  return RewindScrubBeganResponse(
    requestId: 0,
    available: true,
    oldestSequence: oldestSequence,
    newestSequence: newestSequence,
    captureInterval: captureInterval,
    frameRate: frameRate,
    thumbnailSequences: sequences,
    thumbnails: NesBytes.fromList([packed]),
    thumbnailWidth: thumbnailWidth,
    thumbnailHeight: thumbnailHeight,
  );
}

Future<_Harness> _harnessFor(
  _FakeRemoteNes remote, {
  bool rewindEnabled = true,
}) async {
  SharedPreferences.setMockInitialValues({
    'settings': jsonEncode({'rewind': rewindEnabled}),
  });

  final container =
      ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              await SharedPreferences.getInstance(),
            ),
          ],
        )
        ..listen(nesStateProvider, (_, _) {})
        ..listen(rewindScrubControllerProvider, (_, _) {});

  container.read(nesStateProvider.notifier).set(remote);

  return _Harness(container, remote);
}

Future<_Harness> openedController({
  required int oldestSequence,
  required int newestSequence,
  int captureInterval = 4,
  int frameRate = 60,
  int thumbnailWidth = 2,
  int thumbnailHeight = 2,
  List<List<int>>? colors,
}) async {
  final remote = _FakeRemoteNes(
    _response(
      oldestSequence: oldestSequence,
      newestSequence: newestSequence,
      captureInterval: captureInterval,
      frameRate: frameRate,
      thumbnailWidth: thumbnailWidth,
      thumbnailHeight: thumbnailHeight,
      colors: colors,
    ),
  );

  final harness = await _harnessFor(remote);

  final opened = await harness.controller.open();

  if (!opened) {
    throw StateError('expected the session to open');
  }

  return harness;
}

Future<_Harness> unavailableController({bool rewindEnabled = true}) =>
    _harnessFor(_FakeRemoteNes(null), rewindEnabled: rewindEnabled);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('clamps the cursor to the timeline bounds', () async {
    final harness = await openedController(
      oldestSequence: 10,
      newestSequence: 70,
    );
    addTearDown(harness.dispose);

    harness.controller.moveBy(-1000);

    expect(harness.state.cursorSequence, 10);

    harness.controller.moveBy(1000);

    expect(harness.state.cursorSequence, 70);
  });

  test('opens at the newest sequence', () async {
    final harness = await openedController(
      oldestSequence: 10,
      newestSequence: 70,
    );
    addTearDown(harness.dispose);

    expect(harness.state.open, isTrue);
    expect(harness.state.cursorSequence, 70);
  });

  test('moving sends scrubTo', () async {
    final harness = await openedController(
      oldestSequence: 10,
      newestSequence: 70,
    );
    addTearDown(harness.dispose);

    harness.controller.moveBy(-5);

    expect(harness.remote.scrubToCalls, [65]);
  });

  test('moving to the same clamped cursor does not resend', () async {
    final harness = await openedController(
      oldestSequence: 10,
      newestSequence: 70,
    );
    addTearDown(harness.dispose);

    harness.controller.moveBy(5);

    expect(harness.remote.scrubToCalls, isEmpty);
  });

  test('secondsBack converts sequences to elapsed time', () async {
    final harness = await openedController(
      oldestSequence: 10,
      newestSequence: 70,
      captureInterval: 1,
    );
    addTearDown(harness.dispose);

    expect(harness.controller.secondsBack(10), closeTo(1.0, 0.001));
  });

  test('commit closes and disposes the thumbnails', () async {
    final harness = await openedController(
      oldestSequence: 10,
      newestSequence: 70,
    );
    addTearDown(harness.dispose);

    final thumbnails = harness.state.thumbnails;

    harness.controller.commit();

    expect(harness.state.open, isFalse);
    expect(harness.state.thumbnails, isEmpty);
    expect(harness.remote.commitCalls, 1);

    for (final image in thumbnails) {
      expect(image.debugDisposed, isTrue);
    }
  });

  test('cancel closes and disposes the thumbnails', () async {
    final harness = await openedController(
      oldestSequence: 10,
      newestSequence: 70,
    );
    addTearDown(harness.dispose);

    final thumbnails = harness.state.thumbnails;

    harness.controller.cancel();

    expect(harness.state.open, isFalse);
    expect(harness.remote.cancelCalls, 1);

    for (final image in thumbnails) {
      expect(image.debugDisposed, isTrue);
    }
  });

  test('open returns false when the worker has no history', () async {
    final harness = await unavailableController();
    addTearDown(harness.dispose);

    expect(await harness.controller.open(), isFalse);
    expect(harness.state.open, isFalse);
  });

  test('slices each thumbnail from its own stride, not a shared one', () async {
    final harness = await openedController(
      oldestSequence: 10,
      newestSequence: 70,
      colors: [
        [255, 0, 0, 255],
        [0, 0, 255, 255],
      ],
    );
    addTearDown(harness.dispose);

    expect(harness.state.thumbnails, hasLength(2));

    final first = await harness.state.thumbnails[0].toByteData();
    final second = await harness.state.thumbnails[1].toByteData();

    expect(first!.buffer.asUint8List(), _solidPixels(2, 2, [255, 0, 0, 255]));
    expect(second!.buffer.asUint8List(), _solidPixels(2, 2, [0, 0, 255, 255]));
  });

  test('tracks settled from worker position events', () async {
    final harness = await openedController(
      oldestSequence: 10,
      newestSequence: 70,
    );
    addTearDown(harness.dispose);

    expect(harness.state.settled, isTrue);

    harness.remote.emit(
      const RewindScrubPositionEvent(sequence: 65, settled: false),
    );

    await pumpEventQueue();

    expect(harness.state.settled, isFalse);

    harness.remote.emit(
      const RewindScrubPositionEvent(sequence: 65, settled: true),
    );

    await pumpEventQueue();

    expect(harness.state.settled, isTrue);
  });

  test('disposing the provider disposes an open session', () async {
    final harness = await openedController(
      oldestSequence: 10,
      newestSequence: 70,
    );

    final thumbnails = harness.state.thumbnails;

    expect(thumbnails, isNotEmpty);

    harness.container.dispose();

    for (final image in thumbnails) {
      expect(image.debugDisposed, isTrue);
    }

    await harness.remote.close();
  });

  test('two overlapping open() calls do not leak', () async {
    final remote = _FakeRemoteNes(
      _response(oldestSequence: 10, newestSequence: 70),
    );
    final harness = await _harnessFor(remote);
    addTearDown(harness.dispose);

    final results = await Future.wait([
      harness.controller.open(),
      harness.controller.open(),
    ]);

    expect(results, [true, true]);

    expect(remote.beginRewindScrubCalls, 1);
    expect(harness.state.open, isTrue);
    expect(harness.state.thumbnails, hasLength(2));
  });
}
