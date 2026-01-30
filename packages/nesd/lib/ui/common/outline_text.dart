import 'dart:ui';

import 'package:flutter/material.dart';

class StrokeText extends StatelessWidget {
  const StrokeText(
    this.text, {
    this.style,
    this.textAlign,
    this.overflow,
    this.strokeWidth = 0.75,
    this.strokeColor = Colors.black,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final double strokeWidth;
  final Color strokeColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          textAlign: textAlign,
          overflow: overflow,
          style: (style ?? const TextStyle()).copyWith(
            foreground: Paint()
              ..imageFilter = ImageFilter.dilate(
                radiusX: strokeWidth,
                radiusY: strokeWidth,
              )
              ..filterQuality = FilterQuality.high
              ..isAntiAlias = true
              ..color = strokeColor,
          ),
        ),
        Text(text, textAlign: textAlign, overflow: overflow, style: style),
      ],
    );
  }
}
