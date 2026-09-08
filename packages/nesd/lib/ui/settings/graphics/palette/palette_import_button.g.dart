// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'palette_import_button.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The dialog that picks a `.pal` file; tests override it with a fake.

@ProviderFor(palettePicker)
final palettePickerProvider = PalettePickerProvider._();

/// The dialog that picks a `.pal` file; tests override it with a fake.

final class PalettePickerProvider
    extends $FunctionalProvider<PickFile, PickFile, PickFile>
    with $Provider<PickFile> {
  /// The dialog that picks a `.pal` file; tests override it with a fake.
  PalettePickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'palettePickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$palettePickerHash();

  @$internal
  @override
  $ProviderElement<PickFile> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PickFile create(Ref ref) {
    return palettePicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PickFile value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PickFile>(value),
    );
  }
}

String _$palettePickerHash() => r'58abdafa996257eac372cf97af5b3aab2759fb4d';
