import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/common/key_value.dart';
import 'package:nesd/ui/emulator/display_controller.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/remote_nes.dart';
import 'package:nesd/ui/theme/base.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'debug_overlay.freezed.dart';
part 'debug_overlay.g.dart';

@freezed
sealed class DebugOverlayState with _$DebugOverlayState {
  const factory DebugOverlayState({
    @Default(0) double frameTime,
    @Default(0) double fps,
    @Default(0) double sleepTime,
    @Default(0) int frame,
    @Default(0) double rewindSize,
    @Default(FrameDelivery.none) FrameDelivery frameDelivery,
  }) = _DebugOverlayState;
}

@riverpod
class DebugOverlayStateNotifier extends _$DebugOverlayStateNotifier {
  @override
  DebugOverlayState build() {
    return const DebugOverlayState();
  }

  DebugOverlayState get overlayState => state;

  set overlayState(DebugOverlayState state) {
    this.state = state;
  }
}

@riverpod
DebugOverlayController debugOverlayController(Ref ref) {
  final controller = DebugOverlayController(
    notifier: ref.watch(debugOverlayStateProvider.notifier),
    frameController: ref.watch(displayFrameControllerProvider),
  );

  ref
    ..onDispose(controller.dispose)
    ..listen(
      nesStateProvider,
      (_, nes) => controller.updateEvents(nes?.events),
      fireImmediately: true,
    );

  return controller;
}

class DebugOverlayController {
  DebugOverlayController({
    required this.notifier,
    required this.frameController,
  }) {
    frameController.addListener(_handleFrameDelivery);
  }

  final DebugOverlayStateNotifier notifier;
  final DisplayFrameController frameController;

  StreamSubscription<NesIsolateEvent>? _subscription;

  void updateEvents(Stream<NesIsolateEvent>? events) {
    unawaited(_subscription?.cancel());

    _subscription = events
        ?.where((event) => event is FrameEvent)
        .cast<FrameEvent>()
        .listen(_handleEvent);
  }

  void dispose() {
    unawaited(_subscription?.cancel());
    frameController.removeListener(_handleFrameDelivery);
  }

  void _handleEvent(FrameEvent event) {
    final frameTime = event.frameTimeMicroseconds / 1000.0;
    final fps = 1000 / frameTime;
    final sleepTime = event.sleepTimeMicroseconds / 1000.0;

    notifier.overlayState = notifier.overlayState.copyWith(
      frameTime: frameTime,
      frame: event.frame,
      fps: fps,
      sleepTime: sleepTime,
      rewindSize: event.rewindSize / 1024 / 1024,
    );
  }

  void _handleFrameDelivery() {
    notifier.overlayState = notifier.overlayState.copyWith(
      frameDelivery: frameController.value.delivery,
    );
  }
}

class DebugOverlay extends ConsumerWidget {
  const DebugOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(debugOverlayStateProvider);
    final nes = ref.watch(nesStateProvider);

    ref.watch(debugOverlayControllerProvider);

    final color = _getColor(nes, state);

    return Align(
      alignment: Alignment.topRight,
      child: IntrinsicHeight(
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(8),
          color: Colors.black.withValues(alpha: 0.5),
          child: DefaultTextStyle(
            style: DefaultTextStyle.of(
              context,
            ).style.copyWith(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                KeyValue(
                  'Frame Time',
                  state.frameTime.toStringAsFixed(3),
                  color: color,
                ),
                KeyValue('FPS', state.fps.toStringAsFixed(1), color: color),
                KeyValue('Frame', state.frame.toString()),
                KeyValue(
                  'Sleep Time',
                  state.sleepTime.toStringAsFixed(3),
                  color: state.sleepTime <= 0 ? Colors.orange : null,
                ),
                KeyValue(
                  'Rewind Size',
                  '${state.rewindSize.toStringAsFixed(1)} MB',
                ),
                KeyValue('Renderer', switch (state.frameDelivery) {
                  FrameDelivery.gpu => 'GPU',
                  FrameDelivery.cpu => 'CPU',
                  FrameDelivery.none => 'Unknown',
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  MaterialColor? _getColor(RemoteNes? nes, DebugOverlayState state) {
    // RemoteNes does not mirror the worker-side frame rate; the NTSC
    // default of 60 is a good enough threshold for the overlay coloring.
    const targetFrameRate = 60;

    if (state.fps < targetFrameRate ~/ 2) {
      return nesdRed;
    }

    if (state.fps < targetFrameRate - 10) {
      return Colors.orange;
    }

    if (state.fps < targetFrameRate) {
      return Colors.yellow;
    }

    return Colors.green;
  }
}
