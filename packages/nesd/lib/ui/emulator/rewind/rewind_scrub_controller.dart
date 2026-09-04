import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/remote_nes.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rewind_scrub_controller.g.dart';

@immutable
class RewindScrubState {
  const RewindScrubState({
    required this.open,
    required this.cursorSequence,
    required this.oldestSequence,
    required this.newestSequence,
    required this.captureInterval,
    required this.frameRate,
    required this.thumbnails,
    required this.thumbnailSequences,
    required this.settled,
  });

  const RewindScrubState.closed()
    : open = false,
      cursorSequence = 0,
      oldestSequence = 0,
      newestSequence = 0,
      captureInterval = 1,
      frameRate = 60,
      thumbnails = const [],
      thumbnailSequences = const [],
      settled = true;

  final bool open;
  final int cursorSequence;
  final int oldestSequence;
  final int newestSequence;
  final int captureInterval;
  final int frameRate;
  final List<ui.Image> thumbnails;
  final List<int> thumbnailSequences;
  final bool settled;

  RewindScrubState copyWith({int? cursorSequence, bool? settled}) =>
      RewindScrubState(
        open: open,
        cursorSequence: cursorSequence ?? this.cursorSequence,
        oldestSequence: oldestSequence,
        newestSequence: newestSequence,
        captureInterval: captureInterval,
        frameRate: frameRate,
        thumbnails: thumbnails,
        thumbnailSequences: thumbnailSequences,
        settled: settled ?? this.settled,
      );
}

@riverpod
class RewindScrubController extends _$RewindScrubController {
  RemoteNes? _nes;
  StreamSubscription<NesIsolateEvent>? _subscription;

  List<ui.Image> _thumbnails = const [];

  Future<bool>? _opening;

  @override
  RewindScrubState build() {
    ref.listen(nesStateProvider, (_, nes) {
      if (_nes == null || identical(nes, _nes)) {
        return;
      }

      _close();
    });

    ref.onDispose(() {
      _nes?.cancelRewindScrub();

      unawaited(_subscription?.cancel());

      _disposeThumbnails();
    });

    return const RewindScrubState.closed();
  }

  Future<bool> open() {
    if (state.open) {
      return Future.value(true);
    }

    return _opening ??= _openSession().whenComplete(() => _opening = null);
  }

  Future<bool> _openSession() async {
    final nes = ref.read(nesStateProvider);

    if (nes == null) {
      return false;
    }

    final response = await nes.beginRewindScrub();

    if (response == null) {
      nes.cancelRewindScrub();

      _reportUnavailable();

      return false;
    }

    final List<ui.Image> thumbnails;

    try {
      thumbnails = await _decodeThumbnails(response);
    } on Object catch (error, stackTrace) {
      log.emulator.warning(
        'Failed to decode rewind scrub thumbnails',
        error: error,
        stackTrace: stackTrace,
      );

      nes.cancelRewindScrub();

      return false;
    }

    if (!ref.mounted) {
      _disposeImages(thumbnails);

      nes.cancelRewindScrub();

      return false;
    }

    if (!identical(ref.read(nesStateProvider), nes)) {
      _disposeImages(thumbnails);

      nes.cancelRewindScrub();

      return false;
    }

    _nes = nes;
    _thumbnails = thumbnails;
    _subscription = nes.events.listen(_handleEvent);

    state = RewindScrubState(
      open: true,
      cursorSequence: response.newestSequence,
      oldestSequence: response.oldestSequence,
      newestSequence: response.newestSequence,
      captureInterval: response.captureInterval,
      frameRate: response.frameRate,
      thumbnails: thumbnails,
      thumbnailSequences: response.thumbnailSequences,
      settled: true,
    );

    if (!nes.scrubbing) {
      nes.cancelRewindScrub();

      _close();

      return false;
    }

    return true;
  }

  void _reportUnavailable() {
    if (!ref.mounted) {
      return;
    }

    final message = ref.read(settingsControllerProvider).rewind
        ? 'Nothing to rewind yet'
        : 'Rewind is turned off in Settings';

    log.emulator.info('Rewind timeline unavailable: $message');

    ref.read(toasterProvider).send(Toast.info(message));
  }

  void moveBy(int captures) => _moveTo(state.cursorSequence + captures);

  double secondsBack(int sequence) =>
      (state.newestSequence - sequence) *
      state.captureInterval /
      state.frameRate;

  void commit() {
    if (!state.open) {
      return;
    }

    _nes?.commitRewindScrub();

    _close();
  }

  void cancel() {
    if (!state.open) {
      return;
    }

    _nes?.cancelRewindScrub();

    _close();
  }

  void _moveTo(int sequence) {
    if (!state.open) {
      return;
    }

    final clamped = _clamp(sequence);

    if (clamped == state.cursorSequence) {
      return;
    }

    state = state.copyWith(cursorSequence: clamped);

    _nes?.scrubTo(clamped);
  }

  int _clamp(int sequence) {
    if (sequence < state.oldestSequence) {
      return state.oldestSequence;
    }

    if (sequence > state.newestSequence) {
      return state.newestSequence;
    }

    return sequence;
  }

  void _handleEvent(NesIsolateEvent event) {
    if (!state.open) {
      return;
    }

    switch (event) {
      case RewindScrubPositionEvent():
        final settled = _nes?.scrubSettled ?? state.settled;

        if (settled == state.settled) {
          return;
        }

        state = state.copyWith(settled: settled);

      case StatusEvent(scrubbing: false):
        _close();

      default:
        break;
    }
  }

  void _close() {
    unawaited(_subscription?.cancel());

    _subscription = null;
    _nes = null;

    _disposeThumbnails();

    state = const RewindScrubState.closed();
  }

  void _disposeThumbnails() {
    _disposeImages(_thumbnails);

    _thumbnails = const [];
  }

  void _disposeImages(List<ui.Image> images) {
    for (final image in images) {
      image.dispose();
    }
  }

  Future<List<ui.Image>> _decodeThumbnails(
    RewindScrubBeganResponse response,
  ) async {
    final bytes = response.thumbnails.materialize().asUint8List();
    final frameBytes = response.thumbnailWidth * response.thumbnailHeight * 4;
    final images = <ui.Image>[];

    try {
      for (var i = 0; i < response.thumbnailSequences.length; i++) {
        final start = i * frameBytes;
        final slice = Uint8List.sublistView(bytes, start, start + frameBytes);

        images.add(
          await _decodeImage(
            slice,
            response.thumbnailWidth,
            response.thumbnailHeight,
          ),
        );
      }
    } catch (_) {
      for (final image in images) {
        image.dispose();
      }

      rethrow;
    }

    return images;
  }

  Future<ui.Image> _decodeImage(Uint8List pixels, int width, int height) {
    final completer = Completer<ui.Image>();

    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );

    return completer.future;
  }
}
