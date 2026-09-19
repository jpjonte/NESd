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

String _$nesPaletteHash() => r'0917761b29bb2eae3d491808760e120bb0d3755f';
