// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(quitApp)
final quitAppProvider = QuitAppProvider._();

final class QuitAppProvider
    extends $FunctionalProvider<QuitApp, QuitApp, QuitApp>
    with $Provider<QuitApp> {
  QuitAppProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quitAppProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quitAppHash();

  @$internal
  @override
  $ProviderElement<QuitApp> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  QuitApp create(Ref ref) {
    return quitApp(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuitApp value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuitApp>(value),
    );
  }
}

String _$quitAppHash() => r'7a63cc76c652e9b73e09a84185480d8840fb4840';

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

String _$appControllerHash() => r'3283ee9098b00d78c26eed7d407e71ae3b3f4eed';
