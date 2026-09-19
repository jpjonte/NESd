// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_palettes.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(userPaletteStore)
final userPaletteStoreProvider = UserPaletteStoreProvider._();

final class UserPaletteStoreProvider
    extends
        $FunctionalProvider<
          UserPaletteStore,
          UserPaletteStore,
          UserPaletteStore
        >
    with $Provider<UserPaletteStore> {
  UserPaletteStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userPaletteStoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userPaletteStoreHash();

  @$internal
  @override
  $ProviderElement<UserPaletteStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UserPaletteStore create(Ref ref) {
    return userPaletteStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserPaletteStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserPaletteStore>(value),
    );
  }
}

String _$userPaletteStoreHash() => r'8a54694dcfb1b526242fc0bd53a918a908504313';

@ProviderFor(UserPalettes)
final userPalettesProvider = UserPalettesProvider._();

final class UserPalettesProvider
    extends $AsyncNotifierProvider<UserPalettes, Map<String, Uint32List>> {
  UserPalettesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userPalettesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userPalettesHash();

  @$internal
  @override
  UserPalettes create() => UserPalettes();
}

String _$userPalettesHash() => r'380f44bb546444aa029cfca7824045d4af8c94fe';

abstract class _$UserPalettes extends $AsyncNotifier<Map<String, Uint32List>> {
  FutureOr<Map<String, Uint32List>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<String, Uint32List>>,
              Map<String, Uint32List>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, Uint32List>>,
                Map<String, Uint32List>
              >,
              AsyncValue<Map<String, Uint32List>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
