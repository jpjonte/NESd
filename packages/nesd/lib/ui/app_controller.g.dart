// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appController)
final appControllerProvider = AppControllerProvider._();

final class AppControllerProvider
    extends $FunctionalProvider<AppController, AppController, AppController>
    with $Provider<AppController> {
  AppControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appControllerHash();

  @$internal
  @override
  $ProviderElement<AppController> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppController create(Ref ref) {
    return appController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppController>(value),
    );
  }
}

String _$appControllerHash() => r'03263ce314c3bd251f614350df8cbf5253621d54';
