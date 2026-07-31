import 'package:flutter/material.dart';

/// Index to start drawing from: the first rising edge across the
/// midpoint of [samples]' value range, searched within the first
/// quarter of the buffer. 0 when there is none (flat or non-periodic
/// signals). Aligning the draw start to an edge keeps periodic waves
/// visually still across frames.
int findTriggerIndex(List<num> samples) {
  if (samples.length < 2) {
    return 0;
  }

  var min = samples[0];
  var max = samples[0];

  for (final sample in samples) {
    if (sample < min) {
      min = sample;
    }

    if (sample > max) {
      max = sample;
    }
  }

  if (min == max) {
    return 0;
  }

  final threshold = (min + max) / 2;
  final searchEnd = samples.length ~/ 4;

  for (var i = 1; i < searchEnd; i++) {
    if (samples[i - 1] < threshold && samples[i] >= threshold) {
      return i;
    }
  }

  return 0;
}

/// Draws one channel lane's waveform for the APU debug visualizer as a
/// polyline over the frame's samples, scaled to [maxValue].
class ApuWaveformPainter extends CustomPainter {
  ApuWaveformPainter({
    required this.samples,
    required this.maxValue,
    required this.color,
    this.triggered = false,
  });

  final List<num> samples;
  final double maxValue;

  final Color color;

  final bool triggered;

  late final Paint _wavePaint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) {
      return;
    }

    final start = triggered ? findTriggerIndex(samples) : 0;

    // Constant time scale: the visible window always spans 3/4 of the
    // frame's samples so the trigger offset doesn't stretch the wave.
    final windowLength = (samples.length * 3) ~/ 4;
    final end = (start + windowLength).clamp(0, samples.length);
    final span = end - start;

    if (span < 2) {
      return;
    }

    final path = Path();

    for (var i = start; i < end; i++) {
      final x = (i - start) / (span - 1) * size.width;
      final normalized = (samples[i] / maxValue).clamp(0.0, 1.0);
      final y = size.height - normalized * size.height;

      if (i == start) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, _wavePaint);
  }

  @override
  bool shouldRepaint(covariant ApuWaveformPainter oldDelegate) =>
      samples != oldDelegate.samples ||
      maxValue != oldDelegate.maxValue ||
      color != oldDelegate.color ||
      triggered != oldDelegate.triggered;
}
