// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main_menu.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(InitialRom)
final initialRomProvider = InitialRomProvider._();

final class InitialRomProvider
    extends $NotifierProvider<InitialRom, InitialRomSource?> {
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
  Override overrideWithValue(InitialRomSource? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InitialRomSource?>(value),
    );
  }
}

String _$initialRomHash() => r'ab8e2d0b39e4a9c816e439226d31b302ba2a85dc';

abstract class _$InitialRom extends $Notifier<InitialRomSource?> {
  InitialRomSource? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<InitialRomSource?, InitialRomSource?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InitialRomSource?, InitialRomSource?>,
              InitialRomSource?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
