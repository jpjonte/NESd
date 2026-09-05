// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nes_palette_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(nesPalette)
final nesPaletteProvider = NesPaletteProvider._();

final class NesPaletteProvider
    extends $FunctionalProvider<Uint32List, Uint32List, Uint32List>
    with $Provider<Uint32List> {
  NesPaletteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nesPaletteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nesPaletteHash();

  @$internal
  @override
  $ProviderElement<Uint32List> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Uint32List create(Ref ref) {
    return nesPalette(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Uint32List value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Uint32List>(value),
    );
  }
}

String _$nesPaletteHash() => r'4f6430eb7ec3e38722421acdd34c8ab43f60a225';
