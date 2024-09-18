import 'package:flutter/material.dart';
import 'package:nesd/ui/emulator/input/touch/touch_controls.dart';

class AlignTouchControl extends StatelessWidget {
  const AlignTouchControl({
    required this.alignment,
    required this.width,
    required this.height,
    required this.child,
    super.key,
  });

  final Alignment alignment;
  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final touchArea = TouchArea.of(context);

    final halfWidth = touchArea.halfSize.width;
    final halfHeight = touchArea.halfSize.height;

    final center = touchArea.center;

    final x = center.dx + alignment.x * halfWidth;
    final y = center.dy + alignment.y * halfHeight;

    return Positioned(
      left: x - width / 2,
      top: y - height / 2,
      child: child,
    );
  }
}
