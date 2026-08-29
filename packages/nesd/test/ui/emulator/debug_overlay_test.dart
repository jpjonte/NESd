import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/emulator/debug_overlay.dart';
import 'package:nesd/ui/emulator/display_controller.dart';

class _MockDisplayFrameController extends Mock
    implements DisplayFrameController {}

FrameEvent _frameEvent({
  required int frameTimeMicroseconds,
  required int sleepTimeMicroseconds,
}) {
  return FrameEvent(
    frameHandle: 0,
    pixels: InlineFramePixels(bytes: Uint8List(0)),
    width: 256,
    height: 240,
    frameTimeMicroseconds: frameTimeMicroseconds,
    sleepTimeMicroseconds: sleepTimeMicroseconds,
    frame: 1,
    rewindSize: 0,
  );
}

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
          popMax: 0,
        ),
      )
      ..add(
        const AudioStatsEvent(
          timestampMilliseconds: 2,
          exhaustDelta: 2,
          fullDelta: 0,
          fillMin: 900,
          fillMax: 2100,
          popMax: 0,
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
          popMax: 0,
        ),
      )
      ..add(
        const AudioStatsEvent(
          timestampMilliseconds: 2,
          exhaustDelta: 2,
          fullDelta: 0,
          fillMin: 900,
          fillMax: 2100,
          popMax: 0,
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

  test('records every frame in the graph history', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.listen(debugOverlayStateProvider, (_, _) {});

    final controller = DebugOverlayController(
      notifier: container.read(debugOverlayStateProvider.notifier),
      frameController: _MockDisplayFrameController(),
    );
    addTearDown(controller.dispose);

    final events = StreamController<NesIsolateEvent>.broadcast();
    addTearDown(events.close);

    controller.updateEvents(events.stream);

    events.add(
      _frameEvent(frameTimeMicroseconds: 16000, sleepTimeMicroseconds: 4000),
    );

    await Future<void>.delayed(Duration.zero);

    expect(controller.history.length, 1);
    expect(controller.history.workAt(0), 12000);
    expect(controller.history.sleepAt(0), 4000);
  });

  test('clears the graph history when the event stream changes', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.listen(debugOverlayStateProvider, (_, _) {});

    final controller = DebugOverlayController(
      notifier: container.read(debugOverlayStateProvider.notifier),
      frameController: _MockDisplayFrameController(),
    );
    addTearDown(controller.dispose);

    final firstEvents = StreamController<NesIsolateEvent>.broadcast();
    addTearDown(firstEvents.close);

    controller.updateEvents(firstEvents.stream);

    firstEvents.add(
      _frameEvent(frameTimeMicroseconds: 16000, sleepTimeMicroseconds: 4000),
    );

    await Future<void>.delayed(Duration.zero);

    expect(controller.history.length, 1);

    final secondEvents = StreamController<NesIsolateEvent>.broadcast();
    addTearDown(secondEvents.close);

    controller.updateEvents(secondEvents.stream);

    expect(controller.history.length, 0);
  });
}
