import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ShaderFramePainter extends CustomPainter {
  ShaderFramePainter({
    required this.image,
    required this.shader,
    required this.parameters,
  });

  final ui.Image image;
  final ui.FragmentShader shader;
  final List<double> parameters;

  final Paint _backgroundPaint = Paint()..color = Colors.black;
  late final Paint _framePaint = Paint()..shader = shader;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _backgroundPaint);

    shader
      ..setImageSampler(0, image)
      ..setFloat(0, image.width.toDouble())
      ..setFloat(1, image.height.toDouble())
      ..setFloat(2, size.width)
      ..setFloat(3, size.height);

    for (var i = 0; i < parameters.length; i++) {
      shader.setFloat(4 + i, parameters[i]);
    }

    canvas.drawRect(Offset.zero & size, _framePaint);
  }

  @override
  bool shouldRepaint(covariant ShaderFramePainter oldDelegate) {
    return image != oldDelegate.image ||
        shader != oldDelegate.shader ||
        !listEquals(parameters, oldDelegate.parameters);
  }
}
