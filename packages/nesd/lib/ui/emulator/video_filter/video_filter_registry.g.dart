// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_filter_registry.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fragmentProgramLoader)
final fragmentProgramLoaderProvider = FragmentProgramLoaderProvider._();

final class FragmentProgramLoaderProvider
    extends
        $FunctionalProvider<
          FragmentProgramLoader,
          FragmentProgramLoader,
          FragmentProgramLoader
        >
    with $Provider<FragmentProgramLoader> {
  FragmentProgramLoaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fragmentProgramLoaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fragmentProgramLoaderHash();

  @$internal
  @override
  $ProviderElement<FragmentProgramLoader> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FragmentProgramLoader create(Ref ref) {
    return fragmentProgramLoader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FragmentProgramLoader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FragmentProgramLoader>(value),
    );
  }
}

String _$fragmentProgramLoaderHash() =>
    r'8a5b41cd485b0722deb455a44481410290982b3f';

@ProviderFor(VideoFilterRegistry)
final videoFilterRegistryProvider = VideoFilterRegistryProvider._();

final class VideoFilterRegistryProvider
    extends $NotifierProvider<VideoFilterRegistry, VideoFilterShaderState> {
  VideoFilterRegistryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoFilterRegistryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoFilterRegistryHash();

  @$internal
  @override
  VideoFilterRegistry create() => VideoFilterRegistry();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoFilterShaderState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoFilterShaderState>(value),
    );
  }
}

String _$videoFilterRegistryHash() =>
    r'7e1adb99cace02f6d4d064567b0bb62a9f70df14';

abstract class _$VideoFilterRegistry extends $Notifier<VideoFilterShaderState> {
  VideoFilterShaderState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<VideoFilterShaderState, VideoFilterShaderState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VideoFilterShaderState, VideoFilterShaderState>,
              VideoFilterShaderState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(videoFilterActive)
final videoFilterActiveProvider = VideoFilterActiveProvider._();

final class VideoFilterActiveProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  VideoFilterActiveProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoFilterActiveProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoFilterActiveHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return videoFilterActive(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$videoFilterActiveHash() => r'fd52370991c8858741909199605abee688c80e4f';
