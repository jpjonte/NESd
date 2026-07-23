import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/emulator/frame_source.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd_texture/nesd_texture.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'display_controller.g.dart';

@riverpod
DisplayFrameController displayFrameController(Ref ref) {
  final settingsController = ref.read(settingsControllerProvider.notifier);

  final controller = DisplayFrameController(
    settingsController: settingsController,
  );

  ref
    ..onDispose(controller.dispose)
    ..listen(nesStateProvider, (_, nes) {
      controller
        ..updateEvents(nes?.events)
        ..updateFrameSource(nes?.frameSource)
        ..setRunning(nes?.running ?? false);
    }, fireImmediately: true)
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

class DisplayFrameController extends ChangeNotifier
    implements ValueListenable<DisplayFrameState> {
  DisplayFrameController({required this.settingsController});

  final SettingsController settingsController;

  FrameSource? _frameSource;
  RendererPreference _rendererPreference = RendererPreference.auto;

  StreamSubscription<NesIsolateEvent>? _eventSubscription;

  Ticker? _ticker;

  bool _disposed = false;

  DisplayFrameState _state = const EmptyDisplayFrameState();

  bool _inFlight = false;

  static const _maxTextureUpdatesInFlight = 2;

  int _textureUpdatesInFlight = 0;
  bool _textureFailed = false;

  bool _revertingRenderer = false;

  ui.Image? _currentImage;

  NesdTexture? _texture;

  // A queued frame together with the [FrameSource] that produced it. The
  // producing source (not the current [_frameSource]) owns the release, so
  // an in-flight frame is still returned to the right worker even if
  // [updateFrameSource] swaps or nulls the source mid-flight.
  ({FrameHandle handle, FrameSource source})? _pending;

  @override
  DisplayFrameState get value => _state;

  void scheduleFrame() {
    if (_disposed) {
      return;
    }

    final source = _frameSource;
    final handle = source?.takeFrame();

    if (source == null || handle == null) {
      return;
    }

    _processFrame(handle, source);
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    unawaited(_eventSubscription?.cancel());
    _eventSubscription = null;

    _frameSource?.removeListener(_onFrameAvailable);

    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;

    if (_pending case final pending?) {
      pending.source.releaseFrame(pending.handle);

      _pending = null;
    }

    _currentImage?.dispose();
    _currentImage = null;

    _texture = null;

    unawaited(_texture?.dispose());

    _setEmptyFrame();

    super.dispose();
  }

  void updateFrameSource(FrameSource? frameSource) {
    if (_disposed || identical(_frameSource, frameSource)) {
      return;
    }

    _frameSource?.removeListener(_onFrameAvailable);

    if (_pending case final pending?) {
      pending.source.releaseFrame(pending.handle);

      _pending = null;
    }

    _frameSource = frameSource;

    if (frameSource == null) {
      _stopPresenting();

      _setEmptyFrame();

      return;
    }

    frameSource.addListener(_onFrameAvailable);

    scheduleFrame();
  }

  void updateEvents(Stream<NesIsolateEvent>? events) {
    if (_disposed) {
      return;
    }

    unawaited(_eventSubscription?.cancel());

    _eventSubscription = events
        ?.where((event) => event is StatusEvent)
        .cast<StatusEvent>()
        .listen(_handleStatus);

    if (events == null) {
      _stopPresenting();
    }
  }

  void _handleStatus(StatusEvent event) {
    setRunning(event.running);

    // Texture frames no longer notify (identity-stable), so status
    // transitions (pause, fast-forward, rewind, debugger) must trigger
    // the rebuild that repaints the overlay. RemoteNes subscribes to the
    // event stream before this controller, so its status mirrors are
    // already updated when listeners read nes.paused etc.
    notifyListeners();
  }

  // ignore: avoid_positional_boolean_parameters
  void setRunning(bool running) {
    if (running) {
      _startPresenting();

      return;
    }

    _stopPresenting();

    scheduleFrame();
  }

  bool get _presenting => _ticker?.isActive ?? false;

  void _startPresenting() {
    if (_disposed || _presenting) {
      return;
    }

    _ticker ??= Ticker(_onTick);
    _ticker!.start();
  }

  void _stopPresenting() {
    _ticker?.stop();
  }

  void _onTick(Duration elapsed) {
    scheduleFrame();
  }

  void _onFrameAvailable() {
    if (!_presenting) {
      scheduleFrame();
    }
  }

  Future<void> _decodeAndSet(FrameHandle handle, FrameSource source) async {
    ui.Image? image;

    try {
      image = await _decode(handle.bytes, handle.width, handle.height);
    } finally {
      source.releaseFrame(handle);
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
    if (_state case final TextureDisplayFrameState current
        when current.textureId == texture.textureId &&
            current.width == width &&
            current.height == height) {
      // the Texture widget presents new frames by itself;
      // rebuilds are only needed when the texture identity changes
      return;
    }

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

  void _processFrame(FrameHandle handle, FrameSource source) {
    if (_disposed) {
      source.releaseFrame(handle);

      return;
    }

    final width = handle.width;
    final height = handle.height;

    final wantsTexture =
        _rendererPreference != RendererPreference.cpu && !_textureFailed;

    if (wantsTexture) {
      if (_texture case final currentTexture?
          when currentTexture.width != width ||
              currentTexture.height != height) {
        _invalidateTexture();
      }

      if (_texture != null &&
          _textureUpdatesInFlight < _maxTextureUpdatesInFlight) {
        _startTextureUpdate(handle, source);

        return;
      }

      unawaited(_ensureTexture(width, height));

      _enqueuePending(handle, source);

      return;
    }

    if (_inFlight) {
      _enqueuePending(handle, source);

      return;
    }

    _inFlight = true;

    unawaited(_decodeAndSet(handle, source));
  }

  void _startTextureUpdate(FrameHandle handle, FrameSource source) {
    final texture = _texture;

    if (texture == null) {
      source.releaseFrame(handle);

      return;
    }

    _textureUpdatesInFlight++;

    final buffer = handle.bytes;
    final width = handle.width;
    final height = handle.height;

    texture
        .update(buffer, pixelPointer: handle.pointerAddress)
        .whenComplete(() => source.releaseFrame(handle))
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

          _textureUpdatesInFlight--;

          _processPending();
        });
  }

  void _enqueuePending(FrameHandle handle, FrameSource source) {
    if (_pending case final pending?) {
      pending.source.releaseFrame(pending.handle);
    }

    _pending = (handle: handle, source: source);
  }

  void _processPending() {
    if (_disposed) {
      return;
    }

    if (_frameSource == null) {
      // The source was nulled while a frame was queued; release it through
      // the source that produced it so its worker buffer isn't pinned.
      if (_pending case final pending?) {
        pending.source.releaseFrame(pending.handle);

        _pending = null;
      }

      return;
    }

    if (_pending case final pending?) {
      _pending = null;

      _processFrame(pending.handle, pending.source);
    }
  }
}
