// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_toggler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(favoriteToggler)
final favoriteTogglerProvider = FavoriteTogglerProvider._();

final class FavoriteTogglerProvider
    extends
        $FunctionalProvider<FavoriteToggler, FavoriteToggler, FavoriteToggler>
    with $Provider<FavoriteToggler> {
  FavoriteTogglerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteTogglerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteTogglerHash();

  @$internal
  @override
  $ProviderElement<FavoriteToggler> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FavoriteToggler create(Ref ref) {
    return favoriteToggler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavoriteToggler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavoriteToggler>(value),
    );
  }
}

String _$favoriteTogglerHash() => r'086de30c8fba73dda6449f953aff35524cfbac39';
