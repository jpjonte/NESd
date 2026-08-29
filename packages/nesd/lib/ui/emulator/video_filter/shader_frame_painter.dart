import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';

class ShaderFramePainter extends CustomPainter {
  ShaderFramePainter({
    required this.image,
    required this.shader,
    required this.parameters,
    required this.sourceRect,
  });

  final ui.Image image;
  final ui.FragmentShader shader;
  final List<double> parameters;

  final Rect sourceRect;

  final Paint _backgroundPaint = Paint()..color = Colors.black;
  late final Paint _framePaint = Paint()..shader = shader;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _backgroundPaint);

    shader
      ..setImageSampler(0, image)
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, image.width.toDouble())
      ..setFloat(3, image.height.toDouble())
      ..setFloat(4, sourceRect.left)
      ..setFloat(5, sourceRect.top)
      ..setFloat(6, sourceRect.width)
      ..setFloat(7, sourceRect.height);

    for (var i = 0; i < parameters.length; i++) {
      shader.setFloat(videoFilterParameterOffset + i, parameters[i]);
    }

    canvas.drawRect(Offset.zero & size, _framePaint);
  }

  @override
  bool shouldRepaint(covariant ShaderFramePainter oldDelegate) {
    return image != oldDelegate.image ||
        shader != oldDelegate.shader ||
        sourceRect != oldDelegate.sourceRect ||
        !listEquals(parameters, oldDelegate.parameters);
  }
}
