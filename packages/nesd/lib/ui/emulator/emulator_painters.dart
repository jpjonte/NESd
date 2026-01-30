import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class CpuFramePainter extends CustomPainter {
  CpuFramePainter({required this.image});

  final ui.Image image;
  final Paint _backgroundPaint = Paint()..color = Colors.black;
  final Paint _framePaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _backgroundPaint);

    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Offset.zero & size;

    canvas.drawImageRect(image, src, dst, _framePaint);
  }

  @override
  bool shouldRepaint(covariant CpuFramePainter oldDelegate) =>
      image != oldDelegate.image;
}

class EmulatorOverlayPainter extends CustomPainter {
  EmulatorOverlayPainter({
    required this.scale,
    required this.showBorder,
    required this.paused,
    required this.fastForward,
    required this.rewind,
    this.crossHairPosition,
  });

  final double scale;
  final bool showBorder;
  final bool paused;
  final bool fastForward;
  final bool rewind;
  final Offset? crossHairPosition;

  final Paint _pauseOverlayPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.5);
  final Paint _iconPaint = Paint()..color = Colors.white;
  final Paint _outlinePaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;
  final Paint _borderPaint = Paint()
    ..strokeWidth = 1
    ..color = Colors.white
    ..style = PaintingStyle.stroke;
  final Paint _crossHairPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..blendMode = BlendMode.difference
    ..strokeWidth = 4;

  static const List<List<Offset>> _fastForwardTriangles = [
    [Offset(0, -16), Offset(16, 0), Offset(0, 16)],
    [Offset(14, -16), Offset(30, 0), Offset(14, 16)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (showBorder) {
      _drawBorder(canvas, size);
    }

    if (paused) {
      _drawPause(canvas, size);
    } else if (crossHairPosition case final Offset position?) {
      _drawCrossHair(canvas, position * scale);
    }

    if (fastForward) {
      _drawFastForward(canvas, const Offset(8, 24), mirror: false);
    }

    if (rewind) {
      _drawFastForward(canvas, const Offset(32, 24), mirror: true);
    }
  }

  void _drawBorder(Canvas canvas, Size size) {
    const offset = Offset(1, 1);
    canvas.drawRect(
      (Offset.zero - offset) & (size + const Offset(2, 2)),
      _borderPaint,
    );
  }

  void _drawPause(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    canvas
      ..drawRect(Offset.zero & size, _pauseOverlayPaint)
      ..drawRect(center.translate(-16, -16) & const Size(16, 48), _outlinePaint)
      ..drawRect(center.translate(-16, -16) & const Size(16, 48), _iconPaint)
      ..drawRect(center.translate(16, -16) & const Size(16, 48), _outlinePaint)
      ..drawRect(center.translate(16, -16) & const Size(16, 48), _iconPaint);
  }

  void _drawFastForward(Canvas canvas, Offset origin, {required bool mirror}) {
    final path = Path();

    for (final triangle in _fastForwardTriangles) {
      final vertices = triangle
          .map(
            (point) => Offset(mirror ? -point.dx : point.dx, point.dy) + origin,
          )
          .toList();

      path.addPolygon(vertices, true);
    }

    canvas
      ..drawPath(path, _outlinePaint)
      ..drawPath(path, _iconPaint);
  }

  void _drawCrossHair(Canvas canvas, Offset position) {
    final length = 6.0 * scale;

    canvas
      ..drawLine(
        position - Offset(length, 0),
        position + Offset(length, 0),
        _crossHairPaint,
      )
      ..drawLine(
        position - Offset(0, length),
        position + Offset(0, length),
        _crossHairPaint,
      );
  }

  @override
  bool shouldRepaint(covariant EmulatorOverlayPainter oldDelegate) {
    return scale != oldDelegate.scale ||
        showBorder != oldDelegate.showBorder ||
        paused != oldDelegate.paused ||
        fastForward != oldDelegate.fastForward ||
        rewind != oldDelegate.rewind ||
        crossHairPosition != oldDelegate.crossHairPosition;
  }
}
