import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/nes/isolate/apu_debug_state.dart';
import 'package:nesd/ui/emulator/apu_debug/apu_debug_controller.dart';
import 'package:nesd/ui/emulator/apu_debug/apu_debug_data.dart';
import 'package:nesd/ui/emulator/apu_debug/apu_waveform_painter.dart';
import 'package:nesd/ui/emulator/debugger/debugger_widget.dart';

const _pulse1Color = Color(0xff3987e5);
const _pulse2Color = Color(0xffd95926);
const _triangleColor = Color(0xff199e70);
const _noiseColor = Color(0xffc98500);
const _dmcColor = Color(0xffd55181);
const _mixColor = Colors.white;
const _mmc5Pulse1Color = Color(0xff8a63d2);
const _mmc5Pulse2Color = Color(0xff2bb3c0);
const _mmc5PcmColor = Color(0xff9aa832);

const _disabledOpacity = 0.38;

@immutable
class _Param {
  const _Param(this.label, this.value);

  final String label;
  final String value;
}

@immutable
class _LaneStyle {
  _LaneStyle(Color color)
    : this._(color, color.withValues(alpha: _disabledOpacity));

  _LaneStyle._(this.color, Color dimmed)
    : dimmedColor = dimmed,
      nameStyle = monoStyle.copyWith(
        color: color,
        fontVariations: const [FontVariation.weight(700)],
      ),
      dimmedNameStyle = monoStyle.copyWith(
        color: dimmed,
        fontVariations: const [FontVariation.weight(700)],
      ),
      decoration = BoxDecoration(
        color: Colors.black26,
        border: Border(
          left: BorderSide(color: color, width: 3),
          top: const BorderSide(color: Colors.white24),
          right: const BorderSide(color: Colors.white24),
          bottom: const BorderSide(color: Colors.white24),
        ),
      ),
      dimmedDecoration = BoxDecoration(
        color: Colors.black26,
        border: Border(
          left: BorderSide(color: dimmed, width: 3),
          top: const BorderSide(color: Colors.white24),
          right: const BorderSide(color: Colors.white24),
          bottom: const BorderSide(color: Colors.white24),
        ),
      );

  final Color color;
  final Color dimmedColor;
  final TextStyle nameStyle;
  final TextStyle dimmedNameStyle;
  final BoxDecoration decoration;
  final BoxDecoration dimmedDecoration;

  // Dim label, bright value
  static final labelStyle = monoStyle.copyWith(color: Colors.white38);
  static final valueStyle = monoStyle.copyWith(color: Colors.white);
  static final dimmedLabelStyle = monoStyle.copyWith(color: Colors.white24);
  static final dimmedValueStyle = monoStyle.copyWith(color: Colors.white38);

  Color traceColor({required bool enabled}) => enabled ? color : dimmedColor;

  TextStyle name({required bool enabled}) =>
      enabled ? nameStyle : dimmedNameStyle;

  BoxDecoration lane({required bool enabled}) =>
      enabled ? decoration : dimmedDecoration;
}

final _pulse1Style = _LaneStyle(_pulse1Color);
final _pulse2Style = _LaneStyle(_pulse2Color);
final _triangleStyle = _LaneStyle(_triangleColor);
final _noiseStyle = _LaneStyle(_noiseColor);
final _dmcStyle = _LaneStyle(_dmcColor);
final _mixStyle = _LaneStyle(_mixColor);
final _mmc5Pulse1Style = _LaneStyle(_mmc5Pulse1Color);
final _mmc5Pulse2Style = _LaneStyle(_mmc5Pulse2Color);
final _mmc5PcmStyle = _LaneStyle(_mmc5PcmColor);

String _frequency(double value) => '${value.toStringAsFixed(1).padLeft(6)}Hz';

class ApuDebugWidget extends HookConsumerWidget {
  const ApuDebugWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(apuDebugControllerProvider);

    useListenable(controller);

    final data = controller?.data;

    if (data == null) {
      return const SizedBox();
    }

    return Column(
      children: [
        _ApuLane(
          label: 'Pulse 1',
          params: _pulseParams(data, data.pulse1),
          samples: data.pulse1Samples,
          maxValue: 15,
          style: _pulse1Style,
          triggered: true,
          enabled: data.pulse1.enabled,
        ),
        _ApuLane(
          label: 'Pulse 2',
          params: _pulseParams(data, data.pulse2),
          samples: data.pulse2Samples,
          maxValue: 15,
          style: _pulse2Style,
          triggered: true,
          enabled: data.pulse2.enabled,
        ),
        _ApuLane(
          label: 'Triangle',
          params: [
            _Param('FREQ', _frequency(data.triangleFrequency)),
            _Param('NOTE', noteName(data.triangleFrequency).padLeft(4)),
          ],
          samples: data.triangleSamples,
          maxValue: 15,
          style: _triangleStyle,
          triggered: true,
          enabled: data.triangle.enabled,
        ),
        _ApuLane(
          label: 'Noise',
          params: [
            _Param('VOL', '${data.noise.volume}'.padLeft(2)),
            _Param('MODE', data.noiseModeLabel.padRight(5)),
            _Param('PERIOD', '${data.noise.timerPeriod}'.padLeft(4)),
          ],
          samples: data.noiseSamples,
          maxValue: 15,
          style: _noiseStyle,
          enabled: data.noise.enabled,
        ),
        _ApuLane(
          label: 'DMC',
          params: [
            _Param('LVL', '${data.dmc.level}'.padLeft(3)),
            _Param('RATE', '${data.dmc.rate}'.padLeft(4)),
            _Param('BYTES', '${data.dmc.bytesRemaining}'.padLeft(5)),
          ],
          samples: data.dmcSamples,
          maxValue: 127,
          style: _dmcStyle,
          enabled: data.dmc.enabled,
        ),
        if (data.mmc5 case final mmc5?
            when data.expansionSamples.length >= 3) ...[
          _ApuLane(
            label: 'MMC5 Pulse 1',
            params: _pulseParams(data, mmc5.pulse1),
            samples: data.expansionSamples[0],
            maxValue: 15,
            style: _mmc5Pulse1Style,
            triggered: true,
            enabled: mmc5.pulse1.enabled,
          ),
          _ApuLane(
            label: 'MMC5 Pulse 2',
            params: _pulseParams(data, mmc5.pulse2),
            samples: data.expansionSamples[1],
            maxValue: 15,
            style: _mmc5Pulse2Style,
            triggered: true,
            enabled: mmc5.pulse2.enabled,
          ),
          _ApuLane(
            label: 'MMC5 PCM',
            params: [_Param('LVL', '${mmc5.pcmLevel}'.padLeft(3))],
            samples: data.expansionSamples[2],
            maxValue: 255,
            style: _mmc5PcmStyle,
            enabled: mmc5.pcmLevel > 0,
          ),
        ],
        _ApuLane(
          label: 'Mix',
          params: const [],
          samples: data.mixSamples,
          maxValue: 1,
          style: _mixStyle,
        ),
      ],
    );
  }

  List<_Param> _pulseParams(ApuDebugData data, PulseDebugState pulse) {
    final frequency = data.pulseFrequency(pulse);

    return [
      _Param('VOL', '${pulse.volume}'.padLeft(2)),
      _Param('DUTY', data.dutyLabel(pulse).padLeft(5)),
      _Param('FREQ', _frequency(frequency)),
      _Param('NOTE', noteName(frequency).padLeft(4)),
    ];
  }
}

class _ApuLane extends StatelessWidget {
  const _ApuLane({
    required this.label,
    required this.params,
    required this.samples,
    required this.maxValue,
    required this.style,
    this.triggered = false,
    this.enabled = true,
  });

  final String label;
  final List<_Param> params;
  final List<num> samples;
  final double maxValue;
  final _LaneStyle style;
  final bool triggered;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final labelStyle = enabled
        ? _LaneStyle.labelStyle
        : _LaneStyle.dimmedLabelStyle;
    final valueStyle = enabled
        ? _LaneStyle.valueStyle
        : _LaneStyle.dimmedValueStyle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: style.name(enabled: enabled)),
              Row(
                children: [
                  for (final param in params) ...[
                    const SizedBox(width: 12),
                    Text(param.label, style: labelStyle),
                    const SizedBox(width: 4),
                    Text(param.value, style: valueStyle),
                  ],
                ],
              ),
            ],
          ),
          SizedBox(
            height: 40,
            width: double.infinity,
            child: DecoratedBox(
              decoration: style.lane(enabled: enabled),
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: ApuWaveformPainter(
                    samples: samples,
                    maxValue: maxValue,
                    color: style.traceColor(enabled: enabled),
                    triggered: triggered,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
