import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/nes/isolate/apu_debug_state.dart';
import 'package:nesd/nes/isolate/nes_bytes.dart';
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
    channelSamples: NesBytes.fromList([
      Uint8List.fromList(List.generate(laneCount * _count, (i) => i % 16)),
    ]),
    mixSamples: NesBytes.fromList([Float32List(_count)]),
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

ApuDebugEvent _n163Event({int enabledChannels = 8}) {
  const laneCount = 13; // 5 builtin + 8 N163 expansion lanes
  final packed = Uint8List(laneCount * _count);

  for (var j = 0; j < 8; j++) {
    final laneStart = (5 + j) * _count;

    for (var s = 0; s < _count; s++) {
      packed[laneStart + s] = 50 + j * 5 + s;
    }
  }

  return ApuDebugEvent(
    channelSamples: NesBytes.fromList([packed]),
    mixSamples: NesBytes.fromList([Float32List(_count)]),
    sampleCount: _count,
    pulse1: const PulseDebugState(
      enabled: false,
      duty: 0,
      volume: 0,
      timerPeriod: 0,
    ),
    pulse2: const PulseDebugState(
      enabled: false,
      duty: 0,
      volume: 0,
      timerPeriod: 0,
    ),
    triangle: const TriangleDebugState(
      enabled: false,
      timerPeriod: 0,
      linearCounter: 0,
      lengthCounter: 0,
    ),
    noise: const NoiseDebugState(
      enabled: false,
      volume: 0,
      mode: false,
      timerPeriod: 0,
    ),
    dmc: const DmcDebugState(
      enabled: false,
      level: 0,
      rate: 0,
      bytesRemaining: 0,
    ),
    expansionLaneCount: 8,
    mmc5: null,
    n163: Namco163DebugState(
      enabledChannels: enabledChannels,
      channels: List.generate(
        enabledChannels,
        (i) => Namco163ChannelDebugState(
          volume: i + 1,
          waveLength: 100 + i,
          frequency: 20000 + i * 1000,
        ),
        growable: false,
      ),
    ),
    cpuFrequency: 1789773,
  );
}

({Map<String, Set<String>> texts, Map<String, ApuWaveformPainter> painters})
_laneContentByLabel(WidgetTester tester, Set<String> labels) {
  final texts = <String, Set<String>>{};
  final painters = <String, ApuWaveformPainter>{};
  String? currentLabel;

  for (final widget in tester.allWidgets) {
    if (widget is Text && widget.data != null) {
      if (labels.contains(widget.data)) {
        currentLabel = widget.data;
      }

      if (currentLabel != null) {
        texts.putIfAbsent(currentLabel, () => {}).add(widget.data!);
      }
    } else if (currentLabel != null &&
        widget is CustomPaint &&
        widget.painter is ApuWaveformPainter) {
      painters[currentLabel] = widget.painter! as ApuWaveformPainter;
      currentLabel = null;
    }
  }

  return (texts: texts, painters: painters);
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

    testWidgets(
      'N163 CH8 shows channel 8 params and expansionSamples[7], not a '
      'transposed channel',
      (tester) async {
        await pumpPanel(tester);

        handle.emit(_n163Event());
        await tester.pump();

        final rows = _laneContentByLabel(tester, {
          for (var i = 0; i < 8; i++) 'N163 CH${8 - i}',
        });

        expect(
          rows.texts['N163 CH8'],
          contains(' 1'),
          reason: 'CH8 should show channels[0].volume (1)',
        );
        expect(
          rows.texts['N163 CH1'],
          contains(' 8'),
          reason: 'CH1 should show channels[7].volume (8)',
        );

        final ch8Painter = rows.painters['N163 CH8']!;

        expect(ch8Painter.samples, [85, 86, 87, 88, 89, 90, 91, 92]);
        expect(ch8Painter.samples, isNot([50, 51, 52, 53, 54, 55, 56, 57]));

        final ch1Painter = rows.painters['N163 CH1']!;

        expect(ch1Painter.samples, [50, 51, 52, 53, 54, 55, 56, 57]);
      },
    );

    testWidgets('renders exactly enabledChannels N163 lanes', (tester) async {
      await pumpPanel(tester);

      handle.emit(_n163Event(enabledChannels: 3));
      await tester.pump();

      for (final label in ['N163 CH8', 'N163 CH7', 'N163 CH6']) {
        expect(find.text(label), findsOneWidget, reason: 'missing $label lane');
      }

      expect(find.text('N163 CH5'), findsNothing);
    });

    testWidgets('no N163 lanes without a Namco 163 cartridge', (tester) async {
      await pumpPanel(tester);

      handle.emit(_event());
      await tester.pump();

      expect(find.text('N163 CH8'), findsNothing);
    });
  });

  testWidgets('APU debug panel is shown while a game runs when the '
      'setting is on', (tester) async {
    final r = Robot(tester)
      ..initSettings({
        'openTools': ['apuDebug'],
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
