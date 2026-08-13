import 'dart:async';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'video_filter_registry.g.dart';

typedef FragmentProgramLoader =
    Future<ui.FragmentProgram> Function(String assetKey);

@Riverpod(keepAlive: true)
FragmentProgramLoader fragmentProgramLoader(Ref ref) {
  return ui.FragmentProgram.fromAsset;
}

@immutable
class VideoFilterShaderState {
  const VideoFilterShaderState({
    this.shaders = const {},
    this.failed = const {},
  });

  final Map<VideoFilter, ui.FragmentShader> shaders;
  final Set<VideoFilter> failed;

  bool ready(VideoFilter filter) => shaders.containsKey(filter);

  bool hasFailed(VideoFilter filter) => failed.contains(filter);

  VideoFilterShaderState withShader(
    VideoFilter filter,
    ui.FragmentShader shader,
  ) {
    return VideoFilterShaderState(
      shaders: {...shaders, filter: shader},
      failed: failed,
    );
  }

  VideoFilterShaderState withFailed(VideoFilter filter) {
    return VideoFilterShaderState(
      shaders: shaders,
      failed: {...failed, filter},
    );
  }

  static const _mapEquality = MapEquality<VideoFilter, ui.FragmentShader>();
  static const _setEquality = SetEquality<VideoFilter>();

  @override
  bool operator ==(Object other) {
    return other is VideoFilterShaderState &&
        _mapEquality.equals(shaders, other.shaders) &&
        _setEquality.equals(failed, other.failed);
  }

  @override
  int get hashCode =>
      Object.hash(_mapEquality.hash(shaders), _setEquality.hash(failed));
}

@Riverpod(keepAlive: true)
class VideoFilterRegistry extends _$VideoFilterRegistry {
  final _loading = <VideoFilter>{};

  @override
  VideoFilterShaderState build() => const VideoFilterShaderState();

  void ensureLoaded(VideoFilter filter) {
    if (filter == VideoFilter.none) {
      return;
    }

    if (_loading.contains(filter) ||
        state.ready(filter) ||
        state.hasFailed(filter)) {
      return;
    }

    _loading.add(filter);

    unawaited(_load(filter));
  }

  Future<void> _load(VideoFilter filter) async {
    final definition = videoFilterDefinitions[filter]!;
    final loader = ref.read(fragmentProgramLoaderProvider);

    try {
      final program = await loader(definition.asset);

      if (!ref.mounted) {
        return;
      }

      state = state.withShader(filter, program.fragmentShader());
    } on Object {
      if (!ref.mounted) {
        return;
      }

      state = state.withFailed(filter);
    } finally {
      _loading.remove(filter);
    }
  }
}

@riverpod
bool videoFilterActive(Ref ref) {
  final filter = ref.watch(
    settingsControllerProvider.select((s) => s.videoFilter),
  );

  if (filter == VideoFilter.none) {
    return false;
  }

  final failed = ref.watch(
    videoFilterRegistryProvider.select((s) => s.hasFailed(filter)),
  );

  return !failed;
}
