import 'dart:ui';

Offset? nesPositionFromDisplay({
  required Offset displayPosition,
  required double scale,
  required double pixelAspectRatio,
  required int imageWidth,
  required int imageHeight,
}) {
  final position = Offset(
    displayPosition.dx / scale / pixelAspectRatio,
    displayPosition.dy / scale,
  );

  final frameSize = Size(imageWidth.toDouble(), imageHeight.toDouble());

  if (!frameSize.contains(position)) {
    return null;
  }

  return position;
}

Offset displayPositionFromNes({
  required Offset position,
  required double scale,
  required double pixelAspectRatio,
}) {
  return Offset(position.dx * pixelAspectRatio, position.dy) * scale;
}
