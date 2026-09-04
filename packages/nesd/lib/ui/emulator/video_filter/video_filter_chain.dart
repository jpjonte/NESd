import 'dart:ui' as ui;

import 'package:nesd/ui/emulator/video_filter/crt_filter_settings.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';

class VideoFilterChain {
  const VideoFilterChain({required this.filter, required this.key});

  final ui.ImageFilter filter;
  final Object key;
}

VideoFilterChain? composeVideoFilterChain({
  required List<VideoFilter> filters,
  required Map<VideoFilter, ui.FragmentShader> shaders,
  required CrtFilterSettings crtFilter,
  required bool shaderFilterSupported,
  required ui.ImageFilter Function(ui.FragmentShader shader) imageFilterFactory,
  required int sourceWidth,
  required int sourceHeight,
}) {
  if (!shaderFilterSupported) {
    return null;
  }

  final chain = [
    for (final filter in filters)
      if (shaders[filter] case final shader?) (filter: filter, shader: shader),
  ];

  if (chain.isEmpty) {
    return null;
  }

  ui.ImageFilter? composed;

  for (final stage in chain) {
    configureVideoFilterShader(
      stage.shader,
      filter: stage.filter,
      sourceWidth: sourceWidth.toDouble(),
      sourceHeight: sourceHeight.toDouble(),
      crtFilter: crtFilter,
    );

    final stageFilter = imageFilterFactory(stage.shader);

    composed = composed == null
        ? stageFilter
        : ui.ImageFilter.compose(outer: stageFilter, inner: composed);
  }

  return VideoFilterChain(
    filter: composed!,
    key: (
      chain.map((stage) => stage.filter.name).join('+'),
      crtFilter,
      sourceWidth,
      sourceHeight,
    ),
  );
}
