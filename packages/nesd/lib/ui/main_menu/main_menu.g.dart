// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main_menu.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(InitialRom)
final initialRomProvider = InitialRomProvider._();

final class InitialRomProvider extends $NotifierProvider<InitialRom, String?> {
  InitialRomProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'initialRomProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$initialRomHash();

  @$internal
  @override
  InitialRom create() => InitialRom();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$initialRomHash() => r'ff3fa5ae8bc382ca1b1f86e007519a22a04da47e';

abstract class _$InitialRom extends $Notifier<String?> {
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
