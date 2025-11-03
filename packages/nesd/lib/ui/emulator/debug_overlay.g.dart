// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debug_overlay.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DebugOverlayStateNotifier)
final debugOverlayStateProvider = DebugOverlayStateNotifierProvider._();

final class DebugOverlayStateNotifierProvider
    extends $NotifierProvider<DebugOverlayStateNotifier, DebugOverlayState> {
  DebugOverlayStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'debugOverlayStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$debugOverlayStateNotifierHash();

  @$internal
  @override
  DebugOverlayStateNotifier create() => DebugOverlayStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DebugOverlayState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DebugOverlayState>(value),
    );
  }
}

String _$debugOverlayStateNotifierHash() =>
    r'c7b118e5066225ca805b5b4375afebd7ac66c2a2';

abstract class _$DebugOverlayStateNotifier
    extends $Notifier<DebugOverlayState> {
  DebugOverlayState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DebugOverlayState, DebugOverlayState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DebugOverlayState, DebugOverlayState>,
              DebugOverlayState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(debugOverlayController)
final debugOverlayControllerProvider = DebugOverlayControllerProvider._();

final class DebugOverlayControllerProvider
    extends
        $FunctionalProvider<
          DebugOverlayController,
          DebugOverlayController,
          DebugOverlayController
        >
    with $Provider<DebugOverlayController> {
  DebugOverlayControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'debugOverlayControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$debugOverlayControllerHash();

  @$internal
  @override
  $ProviderElement<DebugOverlayController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DebugOverlayController create(Ref ref) {
    return debugOverlayController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DebugOverlayController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DebugOverlayController>(value),
    );
  }
}

String _$debugOverlayControllerHash() =>
    r'0a3ecd6a9798e5ba5af11d493eafe0934b23da08';
