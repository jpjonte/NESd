// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'toaster.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(toaster)
const toasterProvider = ToasterProvider._();

final class ToasterProvider
    extends $FunctionalProvider<Toaster, Toaster, Toaster>
    with $Provider<Toaster> {
  const ToasterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'toasterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$toasterHash();

  @$internal
  @override
  $ProviderElement<Toaster> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Toaster create(Ref ref) {
    return toaster(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Toaster value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Toaster>(value),
    );
  }
}

String _$toasterHash() => r'2830927222b4b7cbe3e48cf7ec0133c86ac4efc9';

@ProviderFor(ToastState)
const toastStateProvider = ToastStateProvider._();

final class ToastStateProvider
    extends $NotifierProvider<ToastState, List<Toast>> {
  const ToastStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'toastStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$toastStateHash();

  @$internal
  @override
  ToastState create() => ToastState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Toast> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Toast>>(value),
    );
  }
}

String _$toastStateHash() => r'88d1781167cc6aeef3d9c286fba818397aed6103';

abstract class _$ToastState extends $Notifier<List<Toast>> {
  List<Toast> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<List<Toast>, List<Toast>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Toast>, List<Toast>>,
              List<Toast>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
