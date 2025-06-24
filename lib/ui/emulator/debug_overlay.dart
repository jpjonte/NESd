import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/common/key_value.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/theme/base.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'debug_overlay.freezed.dart';
part 'debug_overlay.g.dart';

@freezed
sealed class DebugOverlayState with _$DebugOverlayState {
  const factory DebugOverlayState({
    @Default(0) double frameTime,
    @Default(0) double fps,
    @Default(0) double sleepBudget,
    @Default(0) int frame,
    @Default(0) double rewindSize,
  }) = _DebugOverlayState;
}

@riverpod
class DebugOverlayNotifier extends _$DebugOverlayNotifier {
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
    eventBus: ref.watch(eventBusProvider),
    notifier: ref.watch(debugOverlayNotifierProvider.notifier),
  );

  ref.onDispose(controller.dispose);

  return controller;
}

class DebugOverlayController {
  DebugOverlayController({required this.eventBus, required this.notifier}) {
    _subscription = eventBus.stream
        .where((event) => event is FrameNesEvent)
        .cast<FrameNesEvent>()
        .listen(_handleEvent);
  }

  final EventBus eventBus;
  final DebugOverlayNotifier notifier;

  late final StreamSubscription<FrameNesEvent> _subscription;

  void dispose() {
    _subscription.cancel();
  }

  void _handleEvent(FrameNesEvent event) {
    final frameTime = event.frameTime.inMicroseconds / 1000.0;
    final fps = 1000 / frameTime;
    final sleepBudget = event.sleepBudget.inMicroseconds / 1000.0;

    notifier.overlayState = notifier.overlayState.copyWith(
      frameTime: frameTime,
      frame: event.frame,
      fps: fps,
      sleepBudget: sleepBudget,
      rewindSize: event.rewindSize / 1024 / 1024,
    );
  }
}

class DebugOverlay extends ConsumerWidget {
  const DebugOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(debugOverlayNotifierProvider);
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
                  'Sleep Budget',
                  state.sleepBudget.toStringAsFixed(3),
                  color: switch (state.sleepBudget) {
                    < -16 => nesdRed,
                    < 0 => Colors.orange,
                    _ => null,
                  },
                ),
                KeyValue(
                  'Rewind Size',
                  '${state.rewindSize.toStringAsFixed(1)} MB',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  MaterialColor? _getColor(NES? nes, DebugOverlayState state) {
    final targetFrameRate = nes?.frameRate ?? 60;

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
