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
      showDebugOverlay: json['showDebugOverlay'] as bool? ?? false,
      showDebugger: json['showDebugger'] as bool? ?? false,
      scaling: $enumDecodeNullable(_$ScalingEnumMap, json['scaling']) ??
          Scaling.autoInteger,
      autoSave: json['autoSave'] as bool? ?? true,
      autoSaveInterval: (json['autoSaveInterval'] as num?)?.toInt() ?? 1,
      autoLoad: json['autoLoad'] as bool? ?? false,
      bindings: json['bindings'] == null
          ? const {}
          : bindingsFromJson(json['bindings']),
      lastRomPath: json['lastRomPath'] as String? ?? null,
      recentRomPaths: (json['recentRomPaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      recentRoms: (json['recentRoms'] as List<dynamic>?)
              ?.map((e) => RomInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      showTouchControls: json['showTouchControls'] as bool? ?? false,
      narrowTouchInputConfig: json['narrowTouchInputConfig'] == null
          ? const []
          : narrowTouchInputConfigsFromJson(json['narrowTouchInputConfig']),
      wideTouchInputConfig: json['wideTouchInputConfig'] == null
          ? const []
          : wideTouchInputConfigsFromJson(json['wideTouchInputConfig']),
      breakpoints: (json['breakpoints'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
                k,
                (e as List<dynamic>)
                    .map((e) => Breakpoint.fromJson(e as Map<String, dynamic>))
                    .toList()),
          ) ??
          const {},
    );

Map<String, dynamic> _$$SettingsImplToJson(_$SettingsImpl instance) =>
    <String, dynamic>{
      'volume': instance.volume,
      'stretch': instance.stretch,
      'showBorder': instance.showBorder,
      'showTiles': instance.showTiles,
      'showCartridgeInfo': instance.showCartridgeInfo,
      'showDebugOverlay': instance.showDebugOverlay,
      'showDebugger': instance.showDebugger,
      'scaling': _$ScalingEnumMap[instance.scaling]!,
      'autoSave': instance.autoSave,
      'autoSaveInterval': instance.autoSaveInterval,
      'autoLoad': instance.autoLoad,
      'bindings': bindingsToJson(instance.bindings),
      'lastRomPath': instance.lastRomPath,
      'recentRomPaths': instance.recentRomPaths,
      'recentRoms': instance.recentRoms,
      'showTouchControls': instance.showTouchControls,
      'narrowTouchInputConfig': instance.narrowTouchInputConfig,
      'wideTouchInputConfig': instance.wideTouchInputConfig,
      'breakpoints': instance.breakpoints,
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
    r'033265f20dc7edde0270b04b1ecac3de2b07c12b';

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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
