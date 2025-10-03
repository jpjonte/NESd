import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/ppu/frame_buffer.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'display_controller.g.dart';

@riverpod
DisplayFrameController displayFrameController(Ref ref) {
  final eventBus = ref.watch(eventBusProvider);
  final nes = ref.watch(nesStateProvider);

  final controller = DisplayFrameController(
    eventBus: eventBus,
    frameBuffer: nes?.ppu.frameBuffer,
  );

  ref.onDispose(controller.dispose);

  return controller;
}

sealed class DisplayFrameState {
  const DisplayFrameState();
}

class EmptyDisplayFrameState extends DisplayFrameState {
  const EmptyDisplayFrameState();
}

}

class _PendingFrame {
  _PendingFrame(this.bytes, this.width, this.height);

  final Uint8List bytes;

  final int width;
  final int height;
}

class DisplayFrameController extends ChangeNotifier
    implements ValueListenable<DisplayFrameState> {
  DisplayFrameController({required this.eventBus, required this.frameBuffer}) {
    _subscription = eventBus.stream
        .where(
          (event) =>
              event is FrameNesEvent ||
              event is SuspendNesEvent ||
              event is DebuggerNesEvent,
        )
        .listen((_) => scheduleFrame());
  }

  final EventBus eventBus;
  final FrameBuffer? frameBuffer;

  bool _disposed = false;

  DisplayFrameState _state = const EmptyDisplayFrameState();

  bool _inFlight = false;
  bool _lastFastForward = false;

  ui.Image? _currentImage;

  _PendingFrame? _pending;

  StreamSubscription<NesEvent>? _subscription;

  @override
  DisplayFrameState get value => _state;

  void scheduleFrame() {
    if (frameBuffer case final frameBuffer?) {
      final buffer = frameBuffer.takeReadyBuffer();

      if (buffer == null) {
        return;
      }

      final width = frameBuffer.width;
      final height = frameBuffer.height;

      if (_inFlight) {
        final old = _pending;

        if (old != null) {
          frameBuffer.releaseDisplayBuffer(old.bytes);
        }

        _pending = _PendingFrame(buffer, width, height);

        return;
      }

      _inFlight = true;

      unawaited(_decodeAndSet(buffer, width, height));
    }
  }

  void onFastForwardChanged({required bool isFastForward}) {
    final wasFastForward = _lastFastForward;

    _lastFastForward = isFastForward;

    if (wasFastForward && !isFastForward) {
      scheduleFrame();
    }
  }

  @override
  void dispose() {
    _disposed = true;

    _subscription?.cancel();
    _subscription = null;

    if (_pending case final pending?) {
      frameBuffer?.releaseDisplayBuffer(pending.bytes);

      _pending = null;
    }

    _currentImage?.dispose();
    _currentImage = null;

    unawaited(_texture?.dispose());

    _setEmptyFrame();

    super.dispose();
  }

  Future<void> _decodeAndSet(Uint8List bytes, int width, int height) async {
    ui.Image? image;

    try {
      image = await _decode(bytes, width, height);
    } finally {
      frameBuffer?.releaseDisplayBuffer(bytes);
    }

    _setImageFrame(image);

    final next = _pending;

    if (next != null) {
      _pending = null;

      await _decodeAndSet(next.bytes, next.width, next.height);
    } else {
      _inFlight = false;
    }
  }

  Future<ui.Image> _decode(Uint8List bytes, int width, int height) {
    final completer = Completer<ui.Image>();

    ui.decodeImageFromPixels(
      bytes,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );

    return completer.future;
  }

  void _setImageFrame(ui.Image image) {
    if (_disposed) {
      return;
    }

    _currentImage?.dispose();
    _currentImage = image;

    _state = ImageDisplayFrameState(image);

    notifyListeners();
  }

  void _setEmptyFrame() {
    if (_state is EmptyDisplayFrameState) {
      return;
    }

    _currentImage?.dispose();
    _currentImage = null;
    _state = const EmptyDisplayFrameState();
    notifyListeners();
  }
}
