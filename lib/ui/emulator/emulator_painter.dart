import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class EmulatorPainter extends CustomPainter {
  EmulatorPainter({
    required this.image,
    required this.center,
    required this.topLeft,
    required this.screenSize,
    required this.scale,
    required this.showBorder,
    required this.paused,
    required this.fastForward,
    required this.rewind,
    this.crossHairPosition,
  });

  final ui.Image image;

  final Offset center;
  final Offset topLeft;
  final Size screenSize;
  final double scale;

  final bool showBorder;
  final bool paused;
  final bool fastForward;
  final bool rewind;

  final Offset? crossHairPosition;

  final Paint _backgroundPaint = Paint()..color = Colors.black;
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
  final Paint _framePaint = Paint();

  final Path _fastForwardPath = Path()
    ..addPolygon([
      const Offset(0, -16),
      const Offset(16, 0),
      const Offset(0, 16),
    ], true)
    ..addPolygon([
      const Offset(14, -16),
      const Offset(30, 0),
      const Offset(14, 16),
    ], true);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _backgroundPaint);

    _drawScreen(canvas, topLeft, screenSize);

    if (showBorder) {
      _drawBorder(canvas, topLeft, screenSize);
    }

    if (paused) {
      _drawPause(canvas, size, center);
    } else if (crossHairPosition case final Offset position?) {
      _drawCrossHair(canvas, topLeft + position * scale);
    }

    if (fastForward) {
      _drawFastForward(canvas, size, topLeft + const Offset(8, 24));
    }

    if (rewind) {
      _drawFastForward(
        canvas,
        size,
        topLeft + const Offset(32, 24),
        mirror: true,
      );
    }
  }

  void _drawScreen(Canvas canvas, Offset origin, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      origin & size,
      _framePaint,
    );
  }

  void _drawBorder(Canvas canvas, Offset origin, Size size) {
    const offset = Offset(1, 1);

    canvas.drawRect((origin - offset) & size + offset, _borderPaint);
  }

  void _drawPause(Canvas canvas, Size size, Offset center) {
    canvas
      ..drawRect(Offset.zero & size, _pauseOverlayPaint)
      ..drawRect(center.translate(-16, -16) & const Size(16, 48), _outlinePaint)
      ..drawRect(center.translate(-16, -16) & const Size(16, 48), _iconPaint)
      ..drawRect(center.translate(16, -16) & const Size(16, 48), _outlinePaint)
      ..drawRect(center.translate(16, -16) & const Size(16, 48), _iconPaint);
  }

  void _drawFastForward(
    Canvas canvas,
    Size size,
    Offset center, {
    bool mirror = false,
  }) {
    final path = _fastForwardPath
        .transform(Matrix4.diagonal3Values(mirror ? -1 : 1, 1, 1).storage)
        .shift(center);

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
  bool shouldRepaint(covariant EmulatorPainter oldDelegate) {
    return image != oldDelegate.image ||
        center != oldDelegate.center ||
        topLeft != oldDelegate.topLeft ||
        screenSize != oldDelegate.screenSize ||
        scale != oldDelegate.scale ||
        showBorder != oldDelegate.showBorder ||
        paused != oldDelegate.paused ||
        fastForward != oldDelegate.fastForward ||
        rewind != oldDelegate.rewind ||
        crossHairPosition != oldDelegate.crossHairPosition;
  }
}
