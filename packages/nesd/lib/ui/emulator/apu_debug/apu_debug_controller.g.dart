// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apu_debug_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(apuDebugController)
final apuDebugControllerProvider = ApuDebugControllerProvider._();

final class ApuDebugControllerProvider
    extends
        $FunctionalProvider<
          Raw<ApuDebugController?>?,
          Raw<ApuDebugController?>?,
          Raw<ApuDebugController?>?
        >
    with $Provider<Raw<ApuDebugController?>?> {
  ApuDebugControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apuDebugControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apuDebugControllerHash();

  @$internal
  @override
  $ProviderElement<Raw<ApuDebugController?>?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Raw<ApuDebugController?>? create(Ref ref) {
    return apuDebugController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Raw<ApuDebugController?>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Raw<ApuDebugController?>?>(value),
    );
  }
}

String _$apuDebugControllerHash() =>
    r'40d9f9231ad5ae1e7481b1b081f0dc40dae89d9a';
