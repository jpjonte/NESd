// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rom_manager.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RomInfo _$RomInfoFromJson(Map<String, dynamic> json) => RomInfo(
  file: FilesystemFile.fromJson(json['file'] as Map<String, dynamic>),
  hash: json['hash'] as String?,
  romHash: json['romHash'] as String?,
  chrHash: json['chrHash'] as String?,
  prgHash: json['prgHash'] as String?,
);

Map<String, dynamic> _$RomInfoToJson(RomInfo instance) => <String, dynamic>{
  'file': instance.file,
  'hash': instance.hash,
  'romHash': instance.romHash,
  'chrHash': instance.chrHash,
  'prgHash': instance.prgHash,
};

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(applicationSupportPath)
const applicationSupportPathProvider = ApplicationSupportPathProvider._();

final class ApplicationSupportPathProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  const ApplicationSupportPathProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'applicationSupportPathProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$applicationSupportPathHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return applicationSupportPath(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$applicationSupportPathHash() =>
    r'd9da2d8890a3ca61b212204a35e0820482a1f82f';

@ProviderFor(romManager)
const romManagerProvider = RomManagerProvider._();

final class RomManagerProvider
    extends $FunctionalProvider<RomManager, RomManager, RomManager>
    with $Provider<RomManager> {
  const RomManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'romManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$romManagerHash();

  @$internal
  @override
  $ProviderElement<RomManager> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RomManager create(Ref ref) {
    return romManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RomManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RomManager>(value),
    );
  }
}

String _$romManagerHash() => r'fcd257ebb821ceba2bf526c57ecf36c4689b306a';
