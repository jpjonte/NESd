import 'package:flutter/foundation.dart';
import 'package:nesd/ui/emulator/video_filter/crt_filter_settings.dart';

enum VideoFilter { none, crt, smooth }

@immutable
class VideoFilterParameter {
  const VideoFilterParameter({
    required this.name,
    required this.min,
    required this.max,
    required this.defaultValue,
  });

  final String name;
  final double min;
  final double max;
  final double defaultValue;
}

@immutable
class VideoFilterDefinition {
  const VideoFilterDefinition({
    required this.asset,
    this.parameters = const [],
  });

  final String asset;
  final List<VideoFilterParameter> parameters;
}

/// Parameter order defines the shader uniform order and must match both the
/// uniform declarations in the .frag files and [videoFilterUniforms].
const videoFilterDefinitions = <VideoFilter, VideoFilterDefinition>{
  VideoFilter.crt: VideoFilterDefinition(
    asset: 'shaders/crt.frag',
    parameters: [
      VideoFilterParameter(
        name: 'Scanline Intensity',
        min: 0,
        max: 1,
        defaultValue: 0.35,
      ),
      VideoFilterParameter(
        name: 'Mask Strength',
        min: 0,
        max: 1,
        defaultValue: 0.25,
      ),
      VideoFilterParameter(
        name: 'Curvature',
        min: 0,
        max: 0.25,
        defaultValue: 0,
      ),
    ],
  ),
  VideoFilter.smooth: VideoFilterDefinition(asset: 'shaders/smooth.frag'),
};

List<double> videoFilterUniforms(VideoFilter filter, CrtFilterSettings crt) {
  return switch (filter) {
    VideoFilter.none || VideoFilter.smooth => const [],
    VideoFilter.crt => [crt.scanlineIntensity, crt.maskStrength, crt.curvature],
  };
}
