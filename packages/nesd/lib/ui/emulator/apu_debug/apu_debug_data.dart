import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:nesd/nes/apu/tables.dart';
import 'package:nesd/nes/isolate/apu_debug_state.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';

const _noteNames = [
  'C-',
  'C#',
  'D-',
  'D#',
  'E-',
  'F-',
  'F#',
  'G-',
  'G#',
  'A-',
  'A#',
  'B-',
];

/// Note name for [frequency] in Hz, formatted FamiTracker-style with a
/// two-character note and an octave (`A-4`, `A#4`). Octaves run -1 to 9.
///
/// Returns `'---'` for frequencies that name no note: non-positive,
/// non-finite (a zero timer period divides to infinity), or outside the
/// 0-127 MIDI range.
String noteName(double frequency) {
  if (!frequency.isFinite || frequency <= 0) {
    return '---';
  }

  final midi = (69 + 12 * (log(frequency / 440) / ln2)).round();

  if (midi < 0 || midi > 127) {
    return '---';
  }

  final octave = (midi ~/ 12) - 1;

  return '${_noteNames[midi % 12]}$octave';
}

/// Immutable UI-side snapshot of one [ApuDebugEvent], with the sample
/// buffers materialized and the derived readouts (frequency, note name,
/// duty) the panel displays.
@immutable
class ApuDebugData {
  const ApuDebugData({
    required this.pulse1Samples,
    required this.pulse2Samples,
    required this.triangleSamples,
    required this.noiseSamples,
    required this.dmcSamples,
    required this.mixSamples,
    required this.pulse1,
    required this.pulse2,
    required this.triangle,
    required this.noise,
    required this.dmc,
    required this.expansionSamples,
    required this.mmc5,
    required this.n163,
    required this.cpuFrequency,
  });

  factory ApuDebugData.fromEvent(ApuDebugEvent event) {
    final samples = event.unpackSamples();

    return ApuDebugData(
      pulse1Samples: samples.pulse1,
      pulse2Samples: samples.pulse2,
      triangleSamples: samples.triangle,
      noiseSamples: samples.noise,
      dmcSamples: samples.dmc,
      mixSamples: samples.mix,
      pulse1: event.pulse1,
      pulse2: event.pulse2,
      triangle: event.triangle,
      noise: event.noise,
      dmc: event.dmc,
      expansionSamples: samples.expansion,
      mmc5: event.mmc5,
      n163: event.n163,
      cpuFrequency: event.cpuFrequency,
    );
  }

  static const _dutyLabels = ['12.5%', '25%', '50%', '75%'];

  final Uint8List pulse1Samples;
  final Uint8List pulse2Samples;
  final Uint8List triangleSamples;
  final Uint8List noiseSamples;
  final Uint8List dmcSamples;
  final Float32List mixSamples;

  final PulseDebugState pulse1;
  final PulseDebugState pulse2;
  final TriangleDebugState triangle;
  final NoiseDebugState noise;
  final DmcDebugState dmc;

  final List<Uint8List> expansionSamples;

  final Mmc5DebugState? mmc5;

  final Namco163DebugState? n163;

  final int cpuFrequency;

  double pulseFrequency(PulseDebugState pulse) =>
      cpuFrequency / (16 * (pulse.timerPeriod + 1));

  double get triangleFrequency =>
      cpuFrequency / (32 * (triangle.timerPeriod + 1));

  double n163Frequency(
    Namco163DebugState n163,
    Namco163ChannelDebugState channel,
  ) =>
      cpuFrequency *
      channel.frequency /
      (n163SlotCycles * 65536 * channel.waveLength * n163.enabledChannels);

  /// Duty percentage for [pulse], or `?<raw>` if the selector is outside 0-3,
  /// so we don't crash inside `build`.
  String dutyLabel(PulseDebugState pulse) =>
      pulse.duty >= 0 && pulse.duty < _dutyLabels.length
      ? _dutyLabels[pulse.duty]
      : '?${pulse.duty}';

  String get noiseModeLabel => noise.mode ? 'short' : 'long';
}
