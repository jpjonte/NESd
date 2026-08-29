import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:nesd/ui/settings/graphics/scaling.dart';

@immutable
class DisplayGeometry {
  const DisplayGeometry({required this.scale, required this.scaledSize});

  final double scale;
  final Size scaledSize;
}

DisplayGeometry calculateDisplayGeometry({
  required BoxConstraints constraints,
  required int visibleWidth,
  required int visibleHeight,
  required double pixelAspectRatio,
  required Scaling scaling,
}) {
  final aspectRatio = visibleWidth / visibleHeight * pixelAspectRatio;
  final effectiveWidth = (aspectRatio * visibleHeight).round();

  final maxScale = min(
    constraints.maxWidth / effectiveWidth,
    constraints.maxHeight / visibleHeight,
  );

  final scale = min(
    maxScale,
    _requestedScale(
      scaling,
      constraints.maxWidth,
      constraints.maxHeight,
      effectiveWidth,
      visibleHeight,
    ),
  );

  final screenSize = Size(effectiveWidth.toDouble(), visibleHeight.toDouble());

  return DisplayGeometry(scale: scale, scaledSize: screenSize * scale);
}

double _requestedScale(
  Scaling scaling,
  double width,
  double height,
  int imageWidth,
  int imageHeight,
) {
  return switch (scaling) {
    .x1 => 1.0,
    .x2 => 2.0,
    .x3 => 3.0,
    .x4 => 4.0,
    .autoInteger => max(
      0.5,
      min(width ~/ imageWidth, height ~/ imageHeight),
    ).toDouble(),
    .autoSmooth => 1000,
  };
}
