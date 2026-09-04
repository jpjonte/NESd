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
  _FakeRemoteNes(this._response, {this.endsSessionDuringDecode = false});

  final RewindScrubBeganResponse? _response;

  /// The worker opens the session and ends it again before the
  /// controller has finished decoding and subscribed, so the status
  /// change that reports it lands in the gap and is never delivered.
  final bool endsSessionDuringDecode;

  final _events = StreamController<NesIsolateEvent>.broadcast();

  final List<int> scrubToCalls = [];
  int commitCalls = 0;
  int cancelCalls = 0;
  int beginRewindScrubCalls = 0;

  // Mirrors RemoteNes.scrubbing, which the real one feeds from the
  // worker's StatusEvents.
  bool _scrubbing = false;

  // Mirrors RemoteNes.scrubSettled, fed from the same events the
  // controller listens to. The real one subscribes in its constructor,
  // ahead of the controller, so the mirror is always current by the time
  // the controller's listener runs; emit() below reproduces that order.
  bool _scrubSettled = true;

  @override
  bool get scrubbing => _scrubbing;

  @override
  bool get scrubSettled => _scrubSettled;

  @override
  Stream<NesIsolateEvent> get events => _events.stream;

  @override
  Future<RewindScrubBeganResponse?> beginRewindScrub() async {
    beginRewindScrubCalls++;

    if (_response == null) {
      return null;
    }

    _scrubbing = !endsSessionDuringDecode;

    return _response;
  }

  @override
  void scrubTo(int sequence) => scrubToCalls.add(sequence);

  @override
  void commitRewindScrub() {
    commitCalls++;
    _scrubbing = false;
  }

  @override
  void cancelRewindScrub() {
    cancelCalls++;
    _scrubbing = false;
  }

  void emit(NesIsolateEvent event) {
    if (event is RewindScrubPositionEvent) {
      _scrubSettled = event.settled;
    }

    _events.add(event);
  }

  /// Ends the worker's session the way the worker itself does: the
  /// change reaches the UI only through the status mirror.
  void endWorkerSession() {
    _scrubbing = false;

    emit(
      const StatusEvent(
        running: true,
        paused: false,
        fastForward: false,
        rewind: false,
        scrubbing: false,
      ),
    );
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
  // Packs fewer thumbnails than the sequence list promises, so the
  // controller's slicing runs off the end of the payload.
  bool truncatedThumbnails = false,
}) {
  final sequences = [oldestSequence, newestSequence];
  final pixelsPerThumbnail = thumbnailWidth * thumbnailHeight * 4;
  final packed = Uint8List(
    pixelsPerThumbnail * (truncatedThumbnails ? 1 : sequences.length),
  );

  for (var i = 0; i < packed.length ~/ pixelsPerThumbnail; i++) {
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

  test('an unchanged position event does not rebuild the state', () async {
    final harness = await openedController(
      oldestSequence: 10,
      newestSequence: 70,
    );
    addTearDown(harness.dispose);

    final before = harness.state;

    harness.remote.emit(
      const RewindScrubPositionEvent(sequence: 65, settled: true),
    );

    await pumpEventQueue();

    expect(identical(harness.state, before), isTrue);
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

  test('closes when the worker reports its session ended', () async {
    final harness = await openedController(
      oldestSequence: 10,
      newestSequence: 70,
    );
    addTearDown(harness.dispose);

    final thumbnails = harness.state.thumbnails;

    harness.remote.endWorkerSession();

    await pumpEventQueue();

    expect(harness.state.open, isFalse);

    for (final image in thumbnails) {
      expect(image.debugDisposed, isTrue);
    }

    expect(harness.remote.cancelCalls, 0);
  });

  test('closes when the session ended while the filmstrip decoded', () async {
    final remote = _FakeRemoteNes(
      _response(oldestSequence: 10, newestSequence: 70),
      endsSessionDuringDecode: true,
    );
    final harness = await _harnessFor(remote);
    addTearDown(harness.dispose);

    expect(await harness.controller.open(), isFalse);
    expect(harness.state.open, isFalse);
    expect(harness.state.thumbnails, isEmpty);
    expect(remote.cancelCalls, 1);
  });

  test('disposing the provider mid-decode ends the worker session', () async {
    final remote = _FakeRemoteNes(
      _response(oldestSequence: 10, newestSequence: 70),
    );
    final harness = await _harnessFor(remote);

    final opening = harness.controller.open();

    harness.container.dispose();

    expect(await opening, isFalse);
    expect(remote.cancelCalls, 1);

    await remote.close();
  });

  test('toasts when there is no rewind history to scrub', () async {
    final harness = await unavailableController();
    addTearDown(harness.dispose);

    expect(await harness.controller.open(), isFalse);
    expect(harness.container.read(toastStateProvider).map((t) => t.message), [
      'Nothing to rewind yet',
    ]);
  });

  test('the toast says so when rewind is switched off', () async {
    final harness = await unavailableController(rewindEnabled: false);
    addTearDown(harness.dispose);

    expect(await harness.controller.open(), isFalse);
    expect(harness.container.read(toastStateProvider).map((t) => t.message), [
      'Rewind is turned off in Settings',
    ]);
  });

  test('cancels the worker session when there is nothing to scrub', () async {
    final harness = await unavailableController();
    addTearDown(harness.dispose);

    expect(await harness.controller.open(), isFalse);
    expect(harness.remote.cancelCalls, 1);
  });

  test('cancels the worker session when the filmstrip cannot decode', () async {
    final remote = _FakeRemoteNes(
      _response(
        oldestSequence: 10,
        newestSequence: 70,
        truncatedThumbnails: true,
      ),
    );
    final harness = await _harnessFor(remote);
    addTearDown(harness.dispose);

    expect(await harness.controller.open(), isFalse);
    expect(harness.state.open, isFalse);
    expect(remote.cancelCalls, 1);
  });

  test('cancels the worker session when the emulator is swapped', () async {
    final remote = _FakeRemoteNes(
      _response(oldestSequence: 10, newestSequence: 70),
    );
    final harness = await _harnessFor(remote);
    addTearDown(harness.dispose);

    final opening = harness.controller.open();

    harness.container.read(nesStateProvider.notifier).clear();

    expect(await opening, isFalse);
    expect(harness.state.open, isFalse);
    expect(remote.cancelCalls, 1);
  });

  test('closes when the emulator it was opened over goes away', () async {
    final harness = await openedController(
      oldestSequence: 10,
      newestSequence: 70,
    );
    addTearDown(harness.dispose);

    final thumbnails = harness.state.thumbnails;

    harness.container.read(nesStateProvider.notifier).clear();

    expect(harness.state.open, isFalse);

    for (final image in thumbnails) {
      expect(image.debugDisposed, isTrue);
    }
  });

  test('disposing the provider cancels the worker session', () async {
    final harness = await openedController(
      oldestSequence: 10,
      newestSequence: 70,
    );

    harness.container.dispose();

    expect(harness.remote.cancelCalls, 1);

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
