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

String _$applicationSupportPathHash() =>
    r'd9da2d8890a3ca61b212204a35e0820482a1f82f';

/// See also [applicationSupportPath].
@ProviderFor(applicationSupportPath)
final applicationSupportPathProvider = AutoDisposeProvider<String>.internal(
  applicationSupportPath,
  name: r'applicationSupportPathProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$applicationSupportPathHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ApplicationSupportPathRef = AutoDisposeProviderRef<String>;
String _$romManagerHash() => r'fcd257ebb821ceba2bf526c57ecf36c4689b306a';

/// See also [romManager].
@ProviderFor(romManager)
final romManagerProvider = AutoDisposeProvider<RomManager>.internal(
  romManager,
  name: r'romManagerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$romManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RomManagerRef = AutoDisposeProviderRef<RomManager>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
