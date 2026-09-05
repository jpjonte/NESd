// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rewind_scrub_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RewindScrubController)
final rewindScrubControllerProvider = RewindScrubControllerProvider._();

final class RewindScrubControllerProvider
    extends $NotifierProvider<RewindScrubController, RewindScrubState> {
  RewindScrubControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rewindScrubControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rewindScrubControllerHash();

  @$internal
  @override
  RewindScrubController create() => RewindScrubController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RewindScrubState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RewindScrubState>(value),
    );
  }
}

String _$rewindScrubControllerHash() =>
    r'49ebc5712de36156658e2b67a8233e0b9bcb32fa';

abstract class _$RewindScrubController extends $Notifier<RewindScrubState> {
  RewindScrubState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RewindScrubState, RewindScrubState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RewindScrubState, RewindScrubState>,
              RewindScrubState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
