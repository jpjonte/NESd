// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'soak_runner.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Null outside soak mode; main.dart overrides it when a soak marker
/// file was found at startup.

@ProviderFor(soakConfig)
final soakConfigProvider = SoakConfigProvider._();

/// Null outside soak mode; main.dart overrides it when a soak marker
/// file was found at startup.

final class SoakConfigProvider
    extends $FunctionalProvider<SoakConfig?, SoakConfig?, SoakConfig?>
    with $Provider<SoakConfig?> {
  /// Null outside soak mode; main.dart overrides it when a soak marker
  /// file was found at startup.
  SoakConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'soakConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$soakConfigHash();

  @$internal
  @override
  $ProviderElement<SoakConfig?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SoakConfig? create(Ref ref) {
    return soakConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SoakConfig? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SoakConfig?>(value),
    );
  }
}

String _$soakConfigHash() => r'ebb5c7f52d39b3b15cfd8111236151ffd4e07464';

/// Instantiating this provider (NesdApp watches it) starts the soak.
///
/// keepAlive, and the router is READ, not watched: routerProvider is a
/// ChangeNotifierProvider, so watching it recomputes this provider — and
/// constructs a fresh runner — on every navigation notification. The
/// controller stays watched deliberately: it pins nesControllerProvider
/// (and its onDispose teardown) alive for the whole unattended run.
/// [SoakRunner]'s process-level launch guard is the last line of defense
/// against any remaining recompute path.

@ProviderFor(soakRunner)
final soakRunnerProvider = SoakRunnerProvider._();

/// Instantiating this provider (NesdApp watches it) starts the soak.
///
/// keepAlive, and the router is READ, not watched: routerProvider is a
/// ChangeNotifierProvider, so watching it recomputes this provider — and
/// constructs a fresh runner — on every navigation notification. The
/// controller stays watched deliberately: it pins nesControllerProvider
/// (and its onDispose teardown) alive for the whole unattended run.
/// [SoakRunner]'s process-level launch guard is the last line of defense
/// against any remaining recompute path.

final class SoakRunnerProvider
    extends $FunctionalProvider<SoakRunner?, SoakRunner?, SoakRunner?>
    with $Provider<SoakRunner?> {
  /// Instantiating this provider (NesdApp watches it) starts the soak.
  ///
  /// keepAlive, and the router is READ, not watched: routerProvider is a
  /// ChangeNotifierProvider, so watching it recomputes this provider — and
  /// constructs a fresh runner — on every navigation notification. The
  /// controller stays watched deliberately: it pins nesControllerProvider
  /// (and its onDispose teardown) alive for the whole unattended run.
  /// [SoakRunner]'s process-level launch guard is the last line of defense
  /// against any remaining recompute path.
  SoakRunnerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'soakRunnerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$soakRunnerHash();

  @$internal
  @override
  $ProviderElement<SoakRunner?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SoakRunner? create(Ref ref) {
    return soakRunner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SoakRunner? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SoakRunner?>(value),
    );
  }
}

String _$soakRunnerHash() => r'235340d990bfdb242bf80bfd3144cf1590be332e';
