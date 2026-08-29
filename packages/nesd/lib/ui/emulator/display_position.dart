import 'dart:ui';

import 'package:nesd/ui/emulator/overscan.dart';

Offset? nesPositionFromDisplay({
  required Offset displayPosition,
  required double scale,
  required double pixelAspectRatio,
  required int imageWidth,
  required int imageHeight,
  Overscan overscan = Overscan.none,
}) {
  final position = Offset(
    displayPosition.dx / scale / pixelAspectRatio,
    displayPosition.dy / scale,
  );

  final visibleSize = Size(
    overscan.visibleWidth(imageWidth).toDouble(),
    overscan.visibleHeight(imageHeight).toDouble(),
  );

  if (!visibleSize.contains(position)) {
    return null;
  }

  return position.translate(overscan.left.toDouble(), overscan.top.toDouble());
}

Offset displayPositionFromNes({
  required Offset position,
  required double scale,
  required double pixelAspectRatio,
  Overscan overscan = Overscan.none,
}) {
  final visible = position.translate(
    -overscan.left.toDouble(),
    -overscan.top.toDouble(),
  );

  return Offset(visible.dx * pixelAspectRatio, visible.dy) * scale;
}
