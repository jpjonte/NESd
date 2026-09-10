// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'palette_editor_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PaletteEditor)
final paletteEditorProvider = PaletteEditorProvider._();

final class PaletteEditorProvider
    extends $NotifierProvider<PaletteEditor, PaletteEditorState?> {
  PaletteEditorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paletteEditorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paletteEditorHash();

  @$internal
  @override
  PaletteEditor create() => PaletteEditor();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaletteEditorState? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PaletteEditorState?>(value),
    );
  }
}

String _$paletteEditorHash() => r'c489bfb82c05ac841fc87bb241c84018a419006a';

abstract class _$PaletteEditor extends $Notifier<PaletteEditorState?> {
  PaletteEditorState? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PaletteEditorState?, PaletteEditorState?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PaletteEditorState?, PaletteEditorState?>,
              PaletteEditorState?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(paletteDraft)
final paletteDraftProvider = PaletteDraftProvider._();

final class PaletteDraftProvider
    extends $FunctionalProvider<Uint32List?, Uint32List?, Uint32List?>
    with $Provider<Uint32List?> {
  PaletteDraftProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paletteDraftProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paletteDraftHash();

  @$internal
  @override
  $ProviderElement<Uint32List?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Uint32List? create(Ref ref) {
    return paletteDraft(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Uint32List? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Uint32List?>(value),
    );
  }
}

String _$paletteDraftHash() => r'41a0c2c7176ffb02e74ad053803db4470f5709c5';
