import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/emulator/display_controller.dart';
import 'package:nesd/ui/emulator/frame_source.dart';
import 'package:nesd/ui/settings/settings.dart';

class _MockSettingsController extends Mock implements SettingsController {}

/// Hands out a single frame and records how many times a frame is released
/// back to it. Completes [released] on the first release so tests can await
/// the (asynchronous) CPU decode without polling.
class _FakeFrameSource extends FrameSource {
  _FakeFrameSource(this._handle);

  FrameHandle? _handle;
  int releaseCount = 0;
  final Completer<void> _released = Completer<void>();

  Future<void> get released => _released.future;

  @override
  FrameHandle? takeFrame() {
    final handle = _handle;

    _handle = null;

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
}
