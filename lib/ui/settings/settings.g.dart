// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeyBinding _$KeyBindingFromJson(Map<String, dynamic> json) => KeyBinding(
      keys: (json['keys'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toSet(),
      action: json['action'] as String,
    );

Map<String, dynamic> _$KeyBindingToJson(KeyBinding instance) =>
    <String, dynamic>{
      'keys': instance.keys.toList(),
      'action': instance.action,
    };

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
      keyMap: (json['keyMap'] as List<dynamic>?)
              ?.map((e) => KeyBinding.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
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
      'keyMap': instance.keyMap,
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
    r'ab61f74da27b734123a297a13e8149ce16efd648';

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
