// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rom_manager.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RomInfo _$RomInfoFromJson(Map<String, dynamic> json) => RomInfo(
      name: json['name'] as String,
      path: json['path'] as String,
      hash: json['hash'] as String,
      slot: (json['slot'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RomInfoToJson(RomInfo instance) => <String, dynamic>{
      'name': instance.name,
      'path': instance.path,
      'hash': instance.hash,
      'slot': instance.slot,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$applicationSupportPathHash() =>
    r'57adfe5da464c78e9b10a4f871396987c5f7237c';

/// See also [applicationSupportPath].
@ProviderFor(applicationSupportPath)
final applicationSupportPathProvider = AutoDisposeProvider<String>.internal(
  applicationSupportPath,
  name: r'applicationSupportPathProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$applicationSupportPathHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ApplicationSupportPathRef = AutoDisposeProviderRef<String>;
String _$romManagerHash() => r'a8fd07919db858601e7b6440f777e30079960398';

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
