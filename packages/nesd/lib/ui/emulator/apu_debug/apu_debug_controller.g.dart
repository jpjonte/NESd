// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apu_debug_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives [ApuDebugController] off the shared [nesStateProvider], mirroring
/// `debugger` (see `lib/nes/debugger/debugger.dart`): Riverpod runs the old
/// provider state's `ref.onDispose` callbacks before the rebuilt provider
/// body runs, so swapping ROMs on a reused worker isolate always disables
/// the old controller before enabling the new one.

@ProviderFor(apuDebugController)
final apuDebugControllerProvider = ApuDebugControllerProvider._();

/// Drives [ApuDebugController] off the shared [nesStateProvider], mirroring
/// `debugger` (see `lib/nes/debugger/debugger.dart`): Riverpod runs the old
/// provider state's `ref.onDispose` callbacks before the rebuilt provider
/// body runs, so swapping ROMs on a reused worker isolate always disables
/// the old controller before enabling the new one.

final class ApuDebugControllerProvider
    extends
        $FunctionalProvider<
          ApuDebugController?,
          ApuDebugController?,
          ApuDebugController?
        >
    with $Provider<ApuDebugController?> {
  /// Drives [ApuDebugController] off the shared [nesStateProvider], mirroring
  /// `debugger` (see `lib/nes/debugger/debugger.dart`): Riverpod runs the old
  /// provider state's `ref.onDispose` callbacks before the rebuilt provider
  /// body runs, so swapping ROMs on a reused worker isolate always disables
  /// the old controller before enabling the new one.
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
  $ProviderElement<ApuDebugController?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ApuDebugController? create(Ref ref) {
    return apuDebugController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApuDebugController? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApuDebugController?>(value),
    );
  }
}

String _$apuDebugControllerHash() =>
    r'8eb520629e697a843f066f97d9d200b0bffedc03';
