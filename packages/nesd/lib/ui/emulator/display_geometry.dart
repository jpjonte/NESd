import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/ui/settings/graphics/scaling.dart';
import 'package:nesd/ui/settings/settings.dart';

const _topAnchorOffset = 40.0;

@immutable
class DisplayGeometry {
  const DisplayGeometry({
    required this.scale,
    required this.scaledSize,
    required this.topLeft,
  });

  final double scale;
  final Size scaledSize;

  final Offset topLeft;
}

DisplayGeometry calculateDisplayGeometry({
  required BoxConstraints constraints,
  required int visibleWidth,
  required int visibleHeight,
  required double pixelAspectRatio,
  required Scaling scaling,
  required bool showTouchControls,
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
  final scaledSize = screenSize * scale;

  final narrow = constraints.maxWidth < constraints.maxHeight;
  final anchorAtTop = showTouchControls && narrow;

  final center = Offset(
    constraints.maxWidth / 2,
    anchorAtTop
        ? constraints.maxHeight / 4 + _topAnchorOffset
        : constraints.maxHeight / 2,
  );

  return DisplayGeometry(
    scale: scale,
    scaledSize: scaledSize,
    topLeft: center - Offset(scaledSize.width / 2, scaledSize.height / 2),
  );
}

double calculatePixelAspectRatio({
  required PixelAspectRatio pixelAspectRatio,
  required double customPixelAspectRatio,
  required Region region,
  required BoxConstraints constraints,
}) {
  return switch (pixelAspectRatio) {
    .auto => switch (region) {
      .ntsc => 8 / 7,
      .pal => 11 / 8,
    },
    .ntsc => 8 / 7,
    .pal => 11 / 8,
    .square => 1,
    .stretch => constraints.maxWidth / constraints.maxHeight,
    .custom => customPixelAspectRatio,
  };
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
