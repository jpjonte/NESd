// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Settings _$SettingsFromJson(Map<String, dynamic> json) => _Settings(
  volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
  stretch: json['stretch'] as bool? ?? true,
  showBorder: json['showBorder'] as bool? ?? false,
  showTiles: json['showTiles'] as bool? ?? false,
  showCartridgeInfo: json['showCartridgeInfo'] as bool? ?? false,
  showDebugOverlay: json['showDebugOverlay'] as bool? ?? false,
  showDebugger: json['showDebugger'] as bool? ?? false,
  scaling:
      $enumDecodeNullable(_$ScalingEnumMap, json['scaling']) ??
      Scaling.autoInteger,
  autoSave: json['autoSave'] as bool? ?? true,
  autoSaveInterval: (json['autoSaveInterval'] as num?)?.toInt() ?? 1,
  autoLoad: json['autoLoad'] as bool? ?? false,
  bindings: json['bindings'] == null
      ? const []
      : bindingsFromJson(json['bindings']),
  lastRomPath: json['lastRomPath'] == null
      ? null
      : _lastRomPathFromJson(json['lastRomPath']),
  recentRomPaths:
      (json['recentRomPaths'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  recentRoms: json['recentRoms'] == null
      ? const []
      : _recentRomsFromJson(json['recentRoms'] as List),
  showTouchControls: json['showTouchControls'] as bool? ?? false,
  narrowTouchInputConfig: json['narrowTouchInputConfig'] == null
      ? const []
      : narrowTouchInputConfigsFromJson(json['narrowTouchInputConfig']),
  wideTouchInputConfig: json['wideTouchInputConfig'] == null
      ? const []
      : wideTouchInputConfigsFromJson(json['wideTouchInputConfig']),
  breakpoints:
      (json['breakpoints'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          k,
          (e as List<dynamic>)
              .map((e) => Breakpoint.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      ) ??
      const {},
  cheats:
      (json['cheats'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          k,
          (e as List<dynamic>)
              .map((e) => Cheat.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      ) ??
      const {},
  region: $enumDecodeNullable(_$RegionEnumMap, json['region']) ?? null,
  themeMode:
      $enumDecodeNullable(_$ThemeModeEnumMap, json['themeMode']) ??
      ThemeMode.system,
);

Map<String, dynamic> _$SettingsToJson(_Settings instance) => <String, dynamic>{
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
  'bindings': instance.bindings,
  'lastRomPath': instance.lastRomPath,
  'recentRomPaths': instance.recentRomPaths,
  'recentRoms': instance.recentRoms,
  'showTouchControls': instance.showTouchControls,
  'narrowTouchInputConfig': instance.narrowTouchInputConfig,
  'wideTouchInputConfig': instance.wideTouchInputConfig,
  'breakpoints': instance.breakpoints,
  'cheats': instance.cheats,
  'region': _$RegionEnumMap[instance.region],
  'themeMode': _$ThemeModeEnumMap[instance.themeMode]!,
};

const _$ScalingEnumMap = {
  Scaling.autoInteger: 'autoInteger',
  Scaling.autoSmooth: 'autoSmooth',
  Scaling.x1: 'x1',
  Scaling.x2: 'x2',
  Scaling.x3: 'x3',
  Scaling.x4: 'x4',
};

const _$RegionEnumMap = {Region.ntsc: 'ntsc', Region.pal: 'pal'};

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SettingsController)
final settingsControllerProvider = SettingsControllerProvider._();

final class SettingsControllerProvider
    extends $NotifierProvider<SettingsController, Settings> {
  SettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsControllerHash();

  @$internal
  @override
  SettingsController create() => SettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Settings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Settings>(value),
    );
  }
}

String _$settingsControllerHash() =>
    r'30bd449c96d5c9b762ad39d1289f8250e076fff6';

abstract class _$SettingsController extends $Notifier<Settings> {
  Settings build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Settings, Settings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Settings, Settings>,
              Settings,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
