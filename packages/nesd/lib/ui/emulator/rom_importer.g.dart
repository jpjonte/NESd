// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rom_importer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(romImporter)
final romImporterProvider = RomImporterProvider._();

final class RomImporterProvider
    extends $FunctionalProvider<RomImporter, RomImporter, RomImporter>
    with $Provider<RomImporter> {
  RomImporterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'romImporterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$romImporterHash();

  @$internal
  @override
  $ProviderElement<RomImporter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RomImporter create(Ref ref) {
    return romImporter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RomImporter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RomImporter>(value),
    );
  }
}

String _$romImporterHash() => r'0ca537bc27805f862c85f6f250af5e03a0fe6ac9';
