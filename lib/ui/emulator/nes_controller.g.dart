// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nes_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NesState)
const nesStateProvider = NesStateProvider._();

final class NesStateProvider extends $NotifierProvider<NesState, NES?> {
  const NesStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nesStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nesStateHash();

  @$internal
  @override
  NesState create() => NesState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NES? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NES?>(value),
    );
  }
}

String _$nesStateHash() => r'fef68870adec07eca347dae54e58a5e0f1dd6e6c';

abstract class _$NesState extends $Notifier<NES?> {
  NES? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<NES?, NES?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NES?, NES?>,
              NES?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(nesController)
const nesControllerProvider = NesControllerProvider._();

final class NesControllerProvider
    extends $FunctionalProvider<NesController, NesController, NesController>
    with $Provider<NesController> {
  const NesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nesControllerHash();

  @$internal
  @override
  $ProviderElement<NesController> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NesController create(Ref ref) {
    return nesController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NesController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NesController>(value),
    );
  }
}

String _$nesControllerHash() => r'eb0d5269ab37ad8fcffa7cfe36cb75c4b36c25cc';
