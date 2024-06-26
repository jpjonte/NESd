// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SettingsImpl _$$SettingsImplFromJson(Map<String, dynamic> json) =>
    _$SettingsImpl(
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      stretch: json['stretch'] as bool? ?? true,
      showBorder: json['showBorder'] as bool? ?? false,
      showTiles: json['showTiles'] as bool? ?? false,
      showCartridgeInfo: json['showCartridgeInfo'] as bool? ?? false,
      scaling: $enumDecodeNullable(_$ScalingEnumMap, json['scaling']) ??
          Scaling.autoInteger,
      autoSaveInterval: (json['autoSaveInterval'] as num?)?.toInt() ?? 1,
      bindings: json['bindings'] == null
          ? const {}
          : bindingsFromJson(json['bindings']),
    );

Map<String, dynamic> _$$SettingsImplToJson(_$SettingsImpl instance) =>
    <String, dynamic>{
      'volume': instance.volume,
      'stretch': instance.stretch,
      'showBorder': instance.showBorder,
      'showTiles': instance.showTiles,
      'showCartridgeInfo': instance.showCartridgeInfo,
      'scaling': _$ScalingEnumMap[instance.scaling]!,
      'autoSaveInterval': instance.autoSaveInterval,
      'bindings': bindingsToJson(instance.bindings),
    };

const _$ScalingEnumMap = {
  Scaling.autoInteger: 'autoInteger',
  Scaling.autoSmooth: 'autoSmooth',
  Scaling.x1: 'x1',
  Scaling.x2: 'x2',
  Scaling.x3: 'x3',
  Scaling.x4: 'x4',
};

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$settingsControllerHash() =>
    r'7dfe2d9da2c872d77b2fcf811f71b58417679bef';

/// See also [SettingsController].
@ProviderFor(SettingsController)
final settingsControllerProvider =
    AutoDisposeNotifierProvider<SettingsController, Settings>.internal(
  SettingsController.new,
  name: r'settingsControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$settingsControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SettingsController = AutoDisposeNotifier<Settings>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
