import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/ppu/frame_buffer.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd_texture/nesd_texture.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'display_controller.g.dart';

@riverpod
DisplayFrameController displayFrameController(Ref ref) {
  final eventBus = ref.watch(eventBusProvider);
  final settingsController = ref.read(settingsControllerProvider.notifier);

  final controller = DisplayFrameController(
    eventBus: eventBus,
    settingsController: settingsController,
  );

  ref
    ..onDispose(controller.dispose)
    ..listen(
      nesStateProvider,
      (_, nes) => controller.updateFrameBuffer(nes?.ppu.frameBuffer),
      fireImmediately: true,
    )
    ..listen(
      settingsControllerProvider.select((value) => value.renderer),
      (_, preference) => controller.updateRendererPreference(preference),
      fireImmediately: true,
    );

  return controller;
}

enum FrameDelivery { none, gpu, cpu }

sealed class DisplayFrameState {
  const DisplayFrameState();

  FrameDelivery get delivery;
}

class EmptyDisplayFrameState extends DisplayFrameState {
  const EmptyDisplayFrameState();

  @override
  FrameDelivery get delivery => FrameDelivery.none;
}

class TextureDisplayFrameState extends DisplayFrameState {
  const TextureDisplayFrameState({
    required this.textureId,
    required this.width,
    required this.height,
  });

  final int textureId;
  final int width;
  final int height;

  @override
  FrameDelivery get delivery => FrameDelivery.gpu;
}

class ImageDisplayFrameState extends DisplayFrameState {
  const ImageDisplayFrameState(this.image);

  final ui.Image image;

  @override
  FrameDelivery get delivery => FrameDelivery.cpu;
}

class _PendingFrame {
  _PendingFrame(this.bytes, this.width, this.height);

  final Uint8List bytes;

  final int width;
  final int height;
}

class DisplayFrameController extends ChangeNotifier
    implements ValueListenable<DisplayFrameState> {
  DisplayFrameController({
    required this.eventBus,
    required this.settingsController,
  }) {
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
  final SettingsController settingsController;

  FrameBuffer? _frameBuffer;
  RendererPreference _rendererPreference = RendererPreference.auto;

  bool _disposed = false;

  DisplayFrameState _state = const EmptyDisplayFrameState();

  bool _inFlight = false;

  bool _textureInFlight = false;
  bool _textureFailed = false;

  bool _revertingRenderer = false;

  ui.Image? _currentImage;

  NesdTexture? _texture;

  _PendingFrame? _pending;

  StreamSubscription<NesEvent>? _subscription;

  @override
  DisplayFrameState get value => _state;

  void scheduleFrame() {
    if (_disposed) {
      return;
    }

    final frameBuffer = _frameBuffer;

    if (frameBuffer == null) {
      return;
    }

    final buffer = frameBuffer.takeReadyBuffer();

    if (buffer == null) {
      return;
    }

    _processFrame(buffer, frameBuffer.width, frameBuffer.height);
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    _subscription?.cancel();
    _subscription = null;

    if (_pending case final pending?) {
      _frameBuffer?.releaseDisplayBuffer(pending.bytes);

      _pending = null;
    }

    _currentImage?.dispose();
    _currentImage = null;

    _texture = null;

    unawaited(_texture?.dispose());

    _setEmptyFrame();

    super.dispose();
  }

  void updateFrameBuffer(FrameBuffer? frameBuffer) {
    if (_disposed || identical(_frameBuffer, frameBuffer)) {
      return;
    }

    _frameBuffer = frameBuffer;

    if (frameBuffer == null) {
      _setEmptyFrame();

      return;
    }

    scheduleFrame();
  }

  Future<void> _decodeAndSet(Uint8List bytes, int width, int height) async {
    ui.Image? image;

    try {
      image = await _decode(bytes, width, height);
    } finally {
      _frameBuffer?.releaseDisplayBuffer(bytes);
    }

    if (_disposed) {
      image.dispose();

      return;
    }

    _setImageFrame(image);

    _inFlight = false;

    _processPending();
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

  Future<void> _ensureTexture(int width, int height) async {
    if (_texture != null || _textureFailed || _disposed) {
      return;
    }

    try {
      _texture = await NesdTexture.create(width: width, height: height);
    } on Object {
      _textureFailed = true;

      if (_rendererPreference == RendererPreference.gpu) {
        _revertForcedRenderer();
      }

      return;
    }

    _processPending();
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

  void _setTextureFrame(NesdTexture texture, int width, int height) {
    _currentImage?.dispose();
    _currentImage = null;

    _state = TextureDisplayFrameState(
      textureId: texture.textureId,
      width: width,
      height: height,
    );

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

  void _invalidateTexture() {
    _texture?.dispose();
    _texture = null;
    _textureFailed = false;
  }

  void _revertForcedRenderer() {
    if (_disposed ||
        _revertingRenderer ||
        _rendererPreference != RendererPreference.gpu) {
      return;
    }

    _revertingRenderer = true;

    settingsController.rendererPreference = RendererPreference.auto;
  }

  void updateRendererPreference(RendererPreference preference) {
    if (_disposed) {
      return;
    }

    if (!_revertingRenderer && _rendererPreference == preference) {
      return;
    }

    _rendererPreference = preference;

    if (preference == RendererPreference.cpu) {
      _invalidateTexture();
    } else if (preference == RendererPreference.gpu) {
      _textureFailed = false;
    }

    if (preference != RendererPreference.gpu) {
      _revertingRenderer = false;
    }

    _processPending();

    scheduleFrame();
  }

  void _processFrame(Uint8List buffer, int width, int height) {
    if (_disposed) {
      _frameBuffer?.releaseDisplayBuffer(buffer);

      return;
    }

    final wantsTexture =
        _rendererPreference != RendererPreference.cpu && !_textureFailed;

    if (wantsTexture) {
      if (_texture case final currentTexture?) {
        if (currentTexture.width != width || currentTexture.height != height) {
          _invalidateTexture();
        }
      }

      if (_texture != null && !_textureInFlight) {
        _startTextureUpdate(buffer, width, height);

        return;
      }

      unawaited(_ensureTexture(width, height));

      _enqueuePending(buffer, width, height);

      return;
    }

    if (_inFlight) {
      _enqueuePending(buffer, width, height);

      return;
    }

    _inFlight = true;

    unawaited(_decodeAndSet(buffer, width, height));
  }

  void _startTextureUpdate(Uint8List buffer, int width, int height) {
    final texture = _texture;

    if (texture == null) {
      _frameBuffer?.releaseDisplayBuffer(buffer);

      return;
    }

    _textureInFlight = true;

    final pixelPointer = _frameBuffer?.pointerForBuffer(buffer);

    texture
        .update(buffer, pixelPointer: pixelPointer)
        .whenComplete(() => _frameBuffer?.releaseDisplayBuffer(buffer))
        .then<void>((_) {
          if (_disposed) {
            return;
          }

          _setTextureFrame(texture, width, height);
        })
        .catchError((Object error, StackTrace stackTrace) {
          if (_disposed) {
            return;
          }

          _textureFailed = true;

          if (_rendererPreference == RendererPreference.gpu) {
            _revertForcedRenderer();
          }

          _setEmptyFrame();
        })
        .whenComplete(() {
          if (_disposed) {
            return;
          }

          _textureInFlight = false;

          _processPending();
        });
  }

  void _enqueuePending(Uint8List buffer, int width, int height) {
    if (_pending case final pending?) {
      _frameBuffer?.releaseDisplayBuffer(pending.bytes);
    }

    _pending = _PendingFrame(buffer, width, height);
  }

  void _processPending() {
    if (_disposed) {
      return;
    }

    if (_frameBuffer == null) {
      _pending = null;

      return;
    }

    if (_pending case final pending?) {
      _pending = null;

      _processFrame(pending.bytes, pending.width, pending.height);
    }
  }
}
