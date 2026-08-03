// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router_observer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The name of the topmost route, or null when the topmost route is unnamed
/// (`showDialog` pushes unnamed routes, so an open dialog reads as null).

@ProviderFor(CurrentRoute)
final currentRouteProvider = CurrentRouteProvider._();

/// The name of the topmost route, or null when the topmost route is unnamed
/// (`showDialog` pushes unnamed routes, so an open dialog reads as null).
final class CurrentRouteProvider
    extends $NotifierProvider<CurrentRoute, String?> {
  /// The name of the topmost route, or null when the topmost route is unnamed
  /// (`showDialog` pushes unnamed routes, so an open dialog reads as null).
  CurrentRouteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentRouteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentRouteHash();

  @$internal
  @override
  CurrentRoute create() => CurrentRoute();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$currentRouteHash() => r'58924f22ae02f85a3bf5a47901718a5d1290b5d9';

/// The name of the topmost route, or null when the topmost route is unnamed
/// (`showDialog` pushes unnamed routes, so an open dialog reads as null).

abstract class _$CurrentRoute extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(nesdRouterObserver)
final nesdRouterObserverProvider = NesdRouterObserverProvider._();

final class NesdRouterObserverProvider
    extends
        $FunctionalProvider<
          NesdRouterObserver,
          NesdRouterObserver,
          NesdRouterObserver
        >
    with $Provider<NesdRouterObserver> {
  NesdRouterObserverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nesdRouterObserverProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nesdRouterObserverHash();

  @$internal
  @override
  $ProviderElement<NesdRouterObserver> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NesdRouterObserver create(Ref ref) {
    return nesdRouterObserver(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NesdRouterObserver value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NesdRouterObserver>(value),
    );
  }
}

String _$nesdRouterObserverHash() =>
    r'6d9b6638cd1aa3f605bcfecc049e55399f1cb845';
