import 'package:flutter/material.dart';
import 'package:nesd/ui/emulator/frame_graph_history.dart';
import 'package:nesd/ui/theme/base.dart';

const _microsecondsPerSecond = 1000000;

const _targetFrameRate = 60;

const frameGraphTargetMicroseconds = _microsecondsPerSecond / _targetFrameRate;

const frameGraphRangeMicroseconds = 2 * frameGraphTargetMicroseconds;

const frameGraphColumns = 184;

const frameGraphHeight = 48.0;

MaterialColor frameRateColor(double fps) {
  if (fps < _targetFrameRate / 2) {
    return nesdRed;
  }

  if (fps < _targetFrameRate - 10) {
    return Colors.orange;
  }

  if (fps < _targetFrameRate) {
    return Colors.yellow;
  }

  return Colors.green;
}

@immutable
class FrameGraphColumn {
  factory FrameGraphColumn({
    required int workMicroseconds,
    required int sleepMicroseconds,
    required double height,
  }) {
    final scale = height / frameGraphRangeMicroseconds;
    final work = (workMicroseconds * scale).clamp(0.0, height);
    final sleep = (sleepMicroseconds * scale).clamp(0.0, height - work);

    return FrameGraphColumn._(
      workHeight: work,
      sleepHeight: sleep,
      clamped:
          workMicroseconds + sleepMicroseconds > frameGraphRangeMicroseconds,
    );
  }

  const FrameGraphColumn._({
    required this.workHeight,
    required this.sleepHeight,
    required this.clamped,
  });

  final double workHeight;
  final double sleepHeight;

  final bool clamped;
}

const _backgroundColor = Colors.black26;
const _targetLineColor = Colors.white38;

const _clampColor = nesdRed;

const _clampHeight = 1.0;

const _sleepOpacity = 0.3;

class FrameGraphPainter extends CustomPainter {
  FrameGraphPainter({required this.history}) : super(repaint: history);

  final FrameGraphHistory history;

  final _workPaints = <Color, Paint>{};
  final _sleepPaints = <Color, Paint>{};

  late final Paint _backgroundPaint = Paint()..color = _backgroundColor;

  late final Paint _targetPaint = Paint()
    ..color = _targetLineColor
    ..strokeWidth = 1;

  late final Paint _clampPaint = Paint()..color = _clampColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _backgroundPaint);

    final columnWidth = size.width / history.capacity;

    for (var i = 0; i < history.length; i++) {
      final work = history.workAt(i);
      final sleep = history.sleepAt(i);

      final column = FrameGraphColumn(
        workMicroseconds: work,
        sleepMicroseconds: sleep,
        height: size.height,
      );

      final x = size.width - (history.length - i) * columnWidth;

      final color = frameRateColor(_microsecondsPerSecond / work);

      if (column.workHeight > 0) {
        canvas.drawRect(
          Rect.fromLTWH(
            x,
            size.height - column.workHeight,
            columnWidth,
            column.workHeight,
          ),
          _workPaints.putIfAbsent(color, () => Paint()..color = color),
        );
      }

      if (column.sleepHeight > 0) {
        canvas.drawRect(
          Rect.fromLTWH(
            x,
            size.height - column.workHeight - column.sleepHeight,
            columnWidth,
            column.sleepHeight,
          ),
          _sleepPaints.putIfAbsent(
            color,
            () => Paint()..color = color.withValues(alpha: _sleepOpacity),
          ),
        );
      }

      if (column.clamped) {
        canvas.drawRect(
          Rect.fromLTWH(x, 0, columnWidth, _clampHeight),
          _clampPaint,
        );
      }
    }

    final targetY =
        size.height *
        (1 - frameGraphTargetMicroseconds / frameGraphRangeMicroseconds);

    canvas.drawLine(
      Offset(0, targetY),
      Offset(size.width, targetY),
      _targetPaint,
    );
  }

  @override
  bool shouldRepaint(FrameGraphPainter oldDelegate) =>
      oldDelegate.history != history;
}
