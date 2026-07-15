import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/emulator/display_controller.dart';
import 'package:nesd/ui/emulator/frame_source.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd_texture/nesd_texture_platform_interface.dart';

class _MockSettingsController extends Mock implements SettingsController {}

class _FakeNesdTexturePlatform extends NesdTexturePlatform {
  int updates = 0;

  @override
  Future<int> createTexture({required int width, required int height}) async {
    return 1;
  }

  @override
  Future<void> updateTexture({
    required int textureId,
    required int width,
    required int height,
    required int length,
    Uint8List? pixels,
    int? pixelPointer,
  }) async {
    updates++;
  }

  @override
  Future<void> disposeTexture({required int textureId}) async {}
}

/// Hands out parked frames and records takes/releases. [produceFrame] parks
/// a frame and notifies listeners, like [RemoteFrameSource.addFrame].
/// Completes [released] on the first release so tests can await the
/// (asynchronous) CPU decode without polling.
class _FakeFrameSource extends FrameSource {
  _FakeFrameSource([this._handle]);

  FrameHandle? _handle;
  int takenFrames = 0;
  int releaseCount = 0;
  final Completer<void> _released = Completer<void>();

  Future<void> get released => _released.future;

  void produceFrame(FrameHandle handle) {
    _handle = handle;

    notifyListeners();
  }

  @override
  FrameHandle? takeFrame() {
    final handle = _handle;

    _handle = null;

    if (handle != null) {
      takenFrames++;
    }

    return handle;
  }

  @override
  void releaseFrame(FrameHandle handle) {
    releaseCount++;

    if (!_released.isCompleted) {
      _released.complete();
    }
  }
}

FrameHandle _handle({int width = 2, int height = 2}) => FrameHandle(
  bytes: Uint8List(width * height * 4),
  width: width,
  height: height,
  pointerAddress: 0,
);

StatusEvent _status({required bool running}) => StatusEvent(
  running: running,
  paused: !running,
  fastForward: false,
  rewind: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DisplayFrameController buildController() {
    final controller = DisplayFrameController(
      settingsController: _MockSettingsController(),
    )..updateRendererPreference(RendererPreference.cpu);

    addTearDown(controller.dispose);

    return controller;
  }

  test('CPU decode releases the frame through its source', () async {
    final source = _FakeFrameSource(_handle());

    buildController().updateFrameSource(source);

    await source.released.timeout(const Duration(seconds: 5));

    expect(source.releaseCount, 1);
  });

  test('frame is released through its producing source after '
      'updateFrameSource(null) mid-decode', () async {
    final source = _FakeFrameSource(_handle());

    // updateFrameSource(source) kicks off scheduleFrame -> _decodeAndSet
    // (decoding asynchronously); updateFrameSource(null) then swaps the
    // source out from under the in-flight decode. With the old
    // release-through-current-_frameSource code this dropped the release
    // (no-op on the now-null source) and pinned the worker buffer.
    buildController()
      ..updateFrameSource(source)
      ..updateFrameSource(null);

    await source.released.timeout(const Duration(seconds: 5));

    expect(source.releaseCount, 1);
  });

  testWidgets('presents frames on ticks, not on arrival, while running', (
    tester,
  ) async {
    final events = StreamController<NesIsolateEvent>.broadcast();
    final source = _FakeFrameSource();

    addTearDown(events.close);

    final controller = buildController()
      ..updateEvents(events.stream)
      ..updateFrameSource(source);

    events.add(_status(running: true));

    await tester.pump();

    source.produceFrame(_handle());

    // The ticker owns presentation while running; arrival must not present.
    expect(source.takenFrames, 0);

    await tester.pump(const Duration(milliseconds: 16));

    expect(source.takenFrames, 1);

    // Stop the ticker before the test body returns, otherwise flutter_test
    // complains that a Ticker is still active.
    controller.dispose();
  });

  testWidgets('starts ticking when wired while the emulator is already '
      'running', (tester) async {
    final events = StreamController<NesIsolateEvent>.broadcast();
    final source = _FakeFrameSource();

    addTearDown(events.close);

    // No StatusEvent is ever delivered on the stream: the initial running
    // status was consumed before this controller existed. The seed alone
    // must engage the ticker.
    final controller = buildController()
      ..updateEvents(events.stream)
      ..updateFrameSource(source)
      ..setRunning(true);

    source.produceFrame(_handle());

    expect(source.takenFrames, 0);

    await tester.pump(const Duration(milliseconds: 16));

    expect(source.takenFrames, 1);

    controller.dispose();
  });

  testWidgets('presents frames on arrival while not running', (tester) async {
    final source = _FakeFrameSource();

    buildController().updateFrameSource(source);

    source.produceFrame(_handle());

    // No running status ever arrived: on-arrival presentation, no ticker.
    expect(source.takenFrames, 1);
  });

  testWidgets('presents the final frame pushed after the emulator stops', (
    tester,
  ) async {
    final events = StreamController<NesIsolateEvent>.broadcast();
    final source = _FakeFrameSource();

    addTearDown(events.close);

    buildController()
      ..updateEvents(events.stream)
      ..updateFrameSource(source);

    events.add(_status(running: true));

    await tester.pump();

    // The worker sends the paused StatusEvent before it pushes the final frame,
    // so the presenter must fall back to on-arrival presentation the moment
    // `running` turns false.
    events.add(_status(running: false));

    await tester.pump();

    source.produceFrame(_handle());

    expect(source.takenFrames, 1);
  });

  test('texture frames notify once while the texture identity is '
      'unchanged', () async {
    final platform = _FakeNesdTexturePlatform();

    final previousPlatform = NesdTexturePlatform.instance;

    NesdTexturePlatform.instance = platform;

    addTearDown(() => NesdTexturePlatform.instance = previousPlatform);

    // default renderer preference (auto) -> GPU texture path
    final controller = DisplayFrameController(
      settingsController: _MockSettingsController(),
    );

    addTearDown(controller.dispose);

    final source = _FakeFrameSource();

    controller.updateFrameSource(source);

    var notifications = 0;

    controller.addListener(() => notifications++);

    for (var i = 0; i < 3; i++) {
      source.produceFrame(_handle());
      await pumpEventQueue();
    }

    expect(platform.updates, greaterThanOrEqualTo(2));
    expect(notifications, 1);
  });

  test('status events notify listeners so the overlay repaints', () async {
    final events = StreamController<NesIsolateEvent>.broadcast();

    addTearDown(events.close);

    final controller = buildController()..updateEvents(events.stream);

    var notifications = 0;

    controller.addListener(() => notifications++);

    events.add(_status(running: false));

    await pumpEventQueue();

    expect(notifications, 1);
  });
}
