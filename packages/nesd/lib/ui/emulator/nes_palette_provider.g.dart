// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nes_palette_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The palette currently selected in settings, resolved to a full table.
///
/// [paletteLibraryProvider] loads its bundled presets asynchronously, so
/// this falls back to the compiled-in default while it's still loading
/// (e.g. on the very first frame after app start). The loading->data
/// transition rebuilds this provider, which re-resolves and re-fires with
/// the real bundled table — see nes_controller's ref.listen.

@ProviderFor(nesPalette)
final nesPaletteProvider = NesPaletteProvider._();

/// The palette currently selected in settings, resolved to a full table.
///
/// [paletteLibraryProvider] loads its bundled presets asynchronously, so
/// this falls back to the compiled-in default while it's still loading
/// (e.g. on the very first frame after app start). The loading->data
/// transition rebuilds this provider, which re-resolves and re-fires with
/// the real bundled table — see nes_controller's ref.listen.

final class NesPaletteProvider
    extends $FunctionalProvider<Uint32List, Uint32List, Uint32List>
    with $Provider<Uint32List> {
  /// The palette currently selected in settings, resolved to a full table.
  ///
  /// [paletteLibraryProvider] loads its bundled presets asynchronously, so
  /// this falls back to the compiled-in default while it's still loading
  /// (e.g. on the very first frame after app start). The loading->data
  /// transition rebuilds this provider, which re-resolves and re-fires with
  /// the real bundled table — see nes_controller's ref.listen.
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

String _$nesPaletteHash() => r'abe48c20ff6784475cb6fbb375072f98259de013';
