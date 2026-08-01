import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/nes/isolate/apu_debug_state.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/emulator/apu_debug/apu_debug_controller.dart';
import 'package:nesd/ui/emulator/apu_debug/apu_debug_widget.dart';
import 'package:nesd/ui/emulator/apu_debug/apu_waveform_painter.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/remote_nes.dart';

import '../../robot.dart';
import '../remote_nes_fixtures.dart';

const _count = 8;

ApuDebugEvent _event({bool mmc5 = false}) {
  // timerPeriod 253 -> 1789773 / (16 * 254) = 440.4 Hz = A-4
  const pulse1 = PulseDebugState(
    enabled: true,
    duty: 2,
    volume: 7,
    timerPeriod: 253,
  );

  // timerPeriod 63 -> 1789773 / (16 * 64) = 1747.8 Hz, one digit wider
  // than pulse 1 -- the case that used to shift the whole row.
  const pulse2 = PulseDebugState(
    enabled: false,
    duty: 0,
    volume: 3,
    timerPeriod: 63,
  );

  final laneCount = 5 + (mmc5 ? 3 : 0);

  return ApuDebugEvent(
    channelSamples: TransferableTypedData.fromList([
      Uint8List.fromList(List.generate(laneCount * _count, (i) => i % 16)),
    ]),
    mixSamples: TransferableTypedData.fromList([Float32List(_count)]),
    sampleCount: _count,
    pulse1: pulse1,
    pulse2: pulse2,
    // timerPeriod 254 -> 1789773 / (32 * 255) = 219.3 Hz, kept distinct
    // from the pulse frequencies so the assertions stay unambiguous.
    triangle: const TriangleDebugState(
      enabled: true,
      timerPeriod: 254,
      linearCounter: 1,
      lengthCounter: 2,
    ),
    noise: const NoiseDebugState(
      enabled: true,
      volume: 9,
      mode: true,
      timerPeriod: 30,
    ),
    dmc: const DmcDebugState(
      enabled: false,
      level: 64,
      rate: 428,
      bytesRemaining: 17,
    ),
    expansionLaneCount: mmc5 ? 3 : 0,
    mmc5: mmc5
        ? const Mmc5DebugState(pulse1: pulse1, pulse2: pulse2, pcmLevel: 200)
        : null,
    n163: null,
    cpuFrequency: 1789773,
  );
}

void main() {
  group('ApuDebugWidget rendering', () {
    late RecordingNesIsolateHandle handle;
    late RemoteNes nes;
    late ApuDebugController controller;

    setUp(() {
      handle = RecordingNesIsolateHandle();
      nes = RemoteNes(
        isolate: handle,
        romInfo: testRomInfo(),
        fileHash: 'hash',
        hasZapper: false,
        cartridgeInfo: testCartridgeInfo(),
      );
      controller = ApuDebugController(nes);
    });

    tearDown(() async {
      controller.dispose();
      nes.dispose();
      await handle.dispose();
    });

    Future<void> pumpPanel(WidgetTester tester) => tester.pumpWidget(
      ProviderScope(
        overrides: [apuDebugControllerProvider.overrideWithValue(controller)],
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: ApuDebugWidget())),
        ),
      ),
    );

    testWidgets('renders nothing until the first frame arrives', (
      tester,
    ) async {
      await pumpPanel(tester);

      expect(find.text('Pulse 1'), findsNothing);
    });

    testWidgets('renders one lane per channel once data arrives', (
      tester,
    ) async {
      await pumpPanel(tester);

      handle.emit(_event());
      await tester.pump();

      for (final label in [
        'Pulse 1',
        'Pulse 2',
        'Triangle',
        'Noise',
        'DMC',
        'Mix',
      ]) {
        expect(find.text(label), findsOneWidget, reason: 'missing $label lane');
      }
    });

    testWidgets('renders labels and values as separate spans', (tester) async {
      await pumpPanel(tester);

      handle.emit(_event());
      await tester.pump();

      // No colon: the label and value are distinct Text widgets.
      expect(find.text('VOL'), findsWidgets);
      expect(find.text('DUTY'), findsWidgets);
      expect(find.text('FREQ'), findsWidgets);
      expect(find.text('NOTE'), findsWidgets);
      expect(find.textContaining(':'), findsNothing);
    });

    testWidgets('renders the derived pulse readouts', (tester) async {
      await pumpPanel(tester);

      handle.emit(_event());
      await tester.pump();

      expect(find.text(' 7'), findsOneWidget);
      expect(find.text('  50%'), findsOneWidget);
      expect(find.text(' 440.4Hz'), findsOneWidget);
      expect(find.text(' A-4'), findsOneWidget);
    });

    testWidgets('pads values so a wider number does not shift the row', (
      tester,
    ) async {
      await pumpPanel(tester);

      handle.emit(_event());
      await tester.pump();

      // Pulse 1 is 440.4 Hz and pulse 2 is 1748.2 Hz. Padded to a fixed
      // cell, both occupy the same width, so neither row moves.
      final frequencies = tester
          .widgetList<Text>(find.textContaining('Hz'))
          .map((text) => text.data!)
          .toList();

      expect(frequencies, contains(' 440.4Hz'));
      expect(frequencies, contains('1747.8Hz'));
      expect(frequencies.map((f) => f.length).toSet(), {8});
    });

    testWidgets('each lane draws its trace in its own colour', (tester) async {
      await pumpPanel(tester);

      handle.emit(_event());
      await tester.pump();

      final colors = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((paint) => paint.painter)
          .whereType<ApuWaveformPainter>()
          .map((painter) => painter.color)
          .toList();

      expect(colors, hasLength(6));
      expect(colors.toSet(), hasLength(6), reason: 'lane colours must differ');
    });

    testWidgets('a disabled channel keeps its hue but dims', (tester) async {
      await pumpPanel(tester);

      handle.emit(_event());
      await tester.pump();

      Color? nameColor(String label) =>
          tester.widget<Text>(find.text(label)).style?.color;

      final enabled = nameColor('Pulse 1')!;
      final disabled = nameColor('Pulse 2')!;

      expect(enabled.a, 1.0);
      expect(disabled.a, lessThan(1.0));

      // Still a hue rather than a grey: a greyed-out label would have
      // equal channels, which is what the old all-white panel did.
      expect(
        {disabled.r, disabled.g, disabled.b},
        hasLength(greaterThan(1)),
        reason: 'disabled lane went grey instead of dimming its hue',
      );
      expect(disabled, isNot(equals(Colors.white38)));
    });

    testWidgets('MMC5 lanes appear only for MMC5 cartridges', (tester) async {
      await pumpPanel(tester);

      handle.emit(_event(mmc5: true));
      await tester.pump();

      expect(find.text('MMC5 Pulse 1'), findsOneWidget);
      expect(find.text('MMC5 Pulse 2'), findsOneWidget);
      expect(find.text('MMC5 PCM'), findsOneWidget);
    });

    testWidgets('no MMC5 lanes without an MMC5 cartridge', (tester) async {
      await pumpPanel(tester);

      handle.emit(_event());
      await tester.pump();

      expect(find.text('MMC5 Pulse 1'), findsNothing);
      expect(find.text('MMC5 PCM'), findsNothing);
    });

    testWidgets('the PCM lane scales to 255', (tester) async {
      await pumpPanel(tester);

      handle.emit(_event(mmc5: true));
      await tester.pump();

      final painters = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((paint) => paint.painter)
          .whereType<ApuWaveformPainter>();

      expect(painters.any((painter) => painter.maxValue == 255), true);
    });
  });

  testWidgets('APU debug panel is shown while a game runs when the '
      'setting is on', (tester) async {
    final r = Robot(tester)
      ..initSettings({
        'showApuDebug': true,
        'recentRoms': [
          {
            'file': {
              'path': '/test/roms/nestest.nes',
              'name': '/test/roms/nestest.nes',
              'type': 'file',
            },
          },
        ],
      });

    await r.pumpApp();
    r.mainMenu.expectMainMenuFound();

    await r.mainMenu.tapFirstRomTile();
    r.emulator.expectEmulatorWidgetFound();

    expect(find.byType(ApuDebugWidget), findsOneWidget);

    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });
}
