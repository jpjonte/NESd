import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/emulator/debug_overlay.dart';
import 'package:nesd/ui/emulator/display_controller.dart';

class _MockDisplayFrameController extends Mock
    implements DisplayFrameController {}

void main() {
  test('accumulates underruns and mirrors fill minimum', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(debugOverlayStateProvider.notifier);

    // debugOverlayStateProvider is autoDispose; without an active listener
    // the container disposes and rebuilds it (resetting state to defaults)
    // shortly after the last read, before the assertions below run.
    container.listen(debugOverlayStateProvider, (_, _) {});

    final controller = DebugOverlayController(
      notifier: notifier,
      frameController: _MockDisplayFrameController(),
    );
    addTearDown(controller.dispose);

    final events = StreamController<NesIsolateEvent>.broadcast();
    addTearDown(events.close);

    controller.updateEvents(events.stream);

    events
      ..add(
        const AudioStatsEvent(
          timestampMilliseconds: 1,
          exhaustDelta: 3,
          fullDelta: 0,
          fillMin: 240,
          fillMax: 2000,
        ),
      )
      ..add(
        const AudioStatsEvent(
          timestampMilliseconds: 2,
          exhaustDelta: 2,
          fullDelta: 0,
          fillMin: 900,
          fillMax: 2100,
        ),
      );

    await Future<void>.delayed(Duration.zero);

    final state = container.read(debugOverlayStateProvider);

    expect(state.underruns, 5);
    expect(state.fillMin, 900);
  });

  test('resets underruns and fill min when the event stream changes', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(debugOverlayStateProvider.notifier);

    container.listen(debugOverlayStateProvider, (_, _) {});

    final controller = DebugOverlayController(
      notifier: notifier,
      frameController: _MockDisplayFrameController(),
    );
    addTearDown(controller.dispose);

    final firstEvents = StreamController<NesIsolateEvent>.broadcast();
    addTearDown(firstEvents.close);

    controller.updateEvents(firstEvents.stream);

    firstEvents
      ..add(
        const AudioStatsEvent(
          timestampMilliseconds: 1,
          exhaustDelta: 3,
          fullDelta: 0,
          fillMin: 240,
          fillMax: 2000,
        ),
      )
      ..add(
        const AudioStatsEvent(
          timestampMilliseconds: 2,
          exhaustDelta: 2,
          fullDelta: 0,
          fillMin: 900,
          fillMax: 2100,
        ),
      );

    await Future<void>.delayed(Duration.zero);

    expect(container.read(debugOverlayStateProvider).underruns, 5);
    expect(container.read(debugOverlayStateProvider).fillMin, 900);

    final secondEvents = StreamController<NesIsolateEvent>.broadcast();
    addTearDown(secondEvents.close);

    controller.updateEvents(secondEvents.stream);

    final state = container.read(debugOverlayStateProvider);

    expect(state.underruns, 0);
    expect(state.fillMin, 0);
  });
}
