// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'palette_library.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(paletteLibrary)
final paletteLibraryProvider = PaletteLibraryProvider._();

final class PaletteLibraryProvider
    extends
        $FunctionalProvider<
          AsyncValue<PaletteLibrary>,
          PaletteLibrary,
          FutureOr<PaletteLibrary>
        >
    with $FutureModifier<PaletteLibrary>, $FutureProvider<PaletteLibrary> {
  PaletteLibraryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paletteLibraryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paletteLibraryHash();

  @$internal
  @override
  $FutureProviderElement<PaletteLibrary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PaletteLibrary> create(Ref ref) {
    return paletteLibrary(ref);
  }
}

String _$paletteLibraryHash() => r'44577ad164425690b719f18b50890dc79f462e57';
