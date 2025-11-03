// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router_observer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RouterObserver)
const routerObserverProvider = RouterObserverProvider._();

final class RouterObserverProvider
    extends $NotifierProvider<RouterObserver, String?> {
  const RouterObserverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routerObserverProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routerObserverHash();

  @$internal
  @override
  RouterObserver create() => RouterObserver();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$routerObserverHash() => r'a00cc83890f24abe5862c9ec3ef62f6656128a4c';

abstract class _$RouterObserver extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
