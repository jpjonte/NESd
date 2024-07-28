import 'package:flutter/material.dart';

class OutlineText extends StatelessWidget {
  const OutlineText(
    this.text, {
    this.style,
    this.blurRadius = 0.9,
    this.intensity = 8,
    this.outlineColor = Colors.black,
  });

  final String text;
  final TextStyle? style;
  final double blurRadius;
  final Color outlineColor;
  final int intensity;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        // ugly hack for outlined text
        shadows: [
          for (var i = 0; i < intensity; i++)
            Shadow(
              color: outlineColor,
              blurRadius: blurRadius,
            ),
        ],
      ),
    );
  }
}
