// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nes_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(nesIsolateSpawner)
final nesIsolateSpawnerProvider = NesIsolateSpawnerProvider._();

final class NesIsolateSpawnerProvider
    extends
        $FunctionalProvider<
          NesIsolateSpawner,
          NesIsolateSpawner,
          NesIsolateSpawner
        >
    with $Provider<NesIsolateSpawner> {
  NesIsolateSpawnerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nesIsolateSpawnerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nesIsolateSpawnerHash();

  @$internal
  @override
  $ProviderElement<NesIsolateSpawner> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NesIsolateSpawner create(Ref ref) {
    return nesIsolateSpawner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NesIsolateSpawner value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NesIsolateSpawner>(value),
    );
  }
}

String _$nesIsolateSpawnerHash() => r'05d6026f149b0d3d04c08764dcc4d5cacc0133bb';

@ProviderFor(NesState)
final nesStateProvider = NesStateProvider._();

final class NesStateProvider extends $NotifierProvider<NesState, RemoteNes?> {
  NesStateProvider._()
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
  Override overrideWithValue(RemoteNes? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RemoteNes?>(value),
    );
  }
}

String _$nesStateHash() => r'42d89b95280dabaaa265f7735ca6885f3028313d';

abstract class _$NesState extends $Notifier<RemoteNes?> {
  RemoteNes? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RemoteNes?, RemoteNes?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RemoteNes?, RemoteNes?>,
              RemoteNes?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(nesController)
final nesControllerProvider = NesControllerProvider._();

final class NesControllerProvider
    extends $FunctionalProvider<NesController, NesController, NesController>
    with $Provider<NesController> {
  NesControllerProvider._()
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

String _$nesControllerHash() => r'20c48d293fb4358ee1273721c5ec06a797db4d2c';
