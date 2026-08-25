import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/isolate/apu_debug_state.dart';
import 'package:nesd/nes/isolate/nes_bytes.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/emulator/apu_debug/apu_debug_controller.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/remote_nes.dart';

import '../remote_nes_fixtures.dart';

ApuDebugEvent _event() => ApuDebugEvent(
  channelSamples: NesBytes.fromList([Uint8List(5)]),
  mixSamples: NesBytes.fromList([Float32List(1)]),
  sampleCount: 1,
  pulse1: const PulseDebugState(
    enabled: true,
    duty: 0,
    volume: 0,
    timerPeriod: 0,
  ),
  pulse2: const PulseDebugState(
    enabled: true,
    duty: 0,
    volume: 0,
    timerPeriod: 0,
  ),
  triangle: const TriangleDebugState(
    enabled: true,
    timerPeriod: 0,
    linearCounter: 0,
    lengthCounter: 0,
  ),
  noise: const NoiseDebugState(
    enabled: true,
    volume: 0,
    mode: false,
    timerPeriod: 0,
  ),
  dmc: const DmcDebugState(enabled: true, level: 0, rate: 0, bytesRemaining: 0),
  expansionLaneCount: 0,
  mmc5: null,
  n163: null,
  cpuFrequency: 1789773,
);

void main() {
  late RecordingNesIsolateHandle handle;
  late RemoteNes nes;

  setUp(() {
    handle = RecordingNesIsolateHandle();
    nes = RemoteNes(
      isolate: handle,
      romInfo: testRomInfo(),
      fileHash: 'hash',
      hasZapper: false,
      cartridgeInfo: testCartridgeInfo(),
    );
  });

  tearDown(() async {
    nes.dispose();
    await handle.dispose();
  });

  test('sends enable on creation and disable on dispose', () {
    final controller = ApuDebugController(nes);

    expect(
      handle.commands.whereType<SetApuDebugEnabledCommand>().single.enabled,
      isTrue,
    );

    controller.dispose();

    final sent = handle.commands.whereType<SetApuDebugEnabledCommand>();

    expect(sent.last.enabled, isFalse);
    expect(sent, hasLength(2));
  });

  test('materializes ApuDebugEvents into data and notifies', () async {
    final controller = ApuDebugController(nes);

    var notified = 0;

    controller.addListener(() => notified++);

    expect(controller.data, isNull);

    handle.emit(_event());

    await Future<void>.delayed(Duration.zero);

    expect(controller.data, isNotNull);
    expect(controller.data!.pulse1Samples, hasLength(1));
    expect(notified, 1);

    controller.dispose();
  });

  test('ignores unrelated events', () async {
    final controller = ApuDebugController(nes);

    handle.emit(const StoppedEvent());

    await Future<void>.delayed(Duration.zero);

    expect(controller.data, isNull);

    controller.dispose();
  });

  group('apuDebugControllerProvider', () {
    test('a ROM swap on a reused isolate disables the old controller before '
        'enabling the new one', () {
      // Both `RemoteNes` instances share one isolate handle, mirroring
      // production: the worker isolate is reused across ROM loads, only
      // the `RemoteNes` proxy is swapped (see `NesState.set`).
      final firstNes = RemoteNes(
        isolate: handle,
        romInfo: testRomInfo(),
        fileHash: 'first',
        hasZapper: false,
        cartridgeInfo: testCartridgeInfo(),
      );

      final secondNes = RemoteNes(
        isolate: handle,
        romInfo: testRomInfo(),
        fileHash: 'second',
        hasZapper: false,
        cartridgeInfo: testCartridgeInfo(),
      );

      addTearDown(firstNes.dispose);
      addTearDown(secondNes.dispose);

      final container = ProviderContainer();

      addTearDown(container.dispose);

      // Keep the autoDispose provider chain alive for the test's
      // duration (see `nes_controller_isolate_test.dart`). `read` after
      // each mutation forces the computed provider's synchronous
      // rebuild instead of waiting on Riverpod's scheduler.
      container.listen(apuDebugControllerProvider, (_, _) {});

      container.read(nesStateProvider.notifier).set(firstNes);
      container.read(apuDebugControllerProvider);

      expect(
        handle.commands.whereType<SetApuDebugEnabledCommand>().single.enabled,
        isTrue,
      );

      container.read(nesStateProvider.notifier).set(secondNes);
      container.read(apuDebugControllerProvider);

      final sent = handle.commands.whereType<SetApuDebugEnabledCommand>();

      expect(sent, hasLength(3));
      expect(sent.elementAt(1).enabled, isFalse);
      expect(sent.last.enabled, isTrue);
    });
  });
}
