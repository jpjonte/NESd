// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Settings _$SettingsFromJson(Map<String, dynamic> json) => _Settings(
  volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
  lowPassFilter: json['lowPassFilter'] as bool? ?? false,
  fastForwardSpeed:
      $enumDecodeNullable(
        _$FastForwardSpeedEnumMap,
        json['fastForwardSpeed'],
      ) ??
      FastForwardSpeed.x2,
  stretch: json['stretch'] as bool? ?? true,
  showBorder: json['showBorder'] as bool? ?? false,
  showDebugOverlay: json['showDebugOverlay'] as bool? ?? false,
  logLevel:
      $enumDecodeNullable(_$LogLevelEnumMap, json['logLevel']) ?? LogLevel.info,
  openTools: json['openTools'] == null
      ? const <EmulatorTool>{}
      : openToolsFromJson(json['openTools']),
  scaling:
      $enumDecodeNullable(_$ScalingEnumMap, json['scaling']) ??
      Scaling.autoSmooth,
  autoSave: json['autoSave'] as bool? ?? true,
  autoSaveInterval: (json['autoSaveInterval'] as num?)?.toInt() ?? 1,
  autoLoad: json['autoLoad'] as bool? ?? true,
  bindings: json['bindings'] == null
      ? const []
      : bindingsFromJson(json['bindings']),
  bindingsVersion: (json['bindingsVersion'] as num?)?.toInt() ?? 2,
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
  renderer:
      $enumDecodeNullable(_$RendererPreferenceEnumMap, json['renderer']) ??
      RendererPreference.auto,
  rewind: json['rewind'] as bool? ?? true,
  pixelAspectRatio:
      $enumDecodeNullable(
        _$PixelAspectRatioEnumMap,
        json['pixelAspectRatio'],
      ) ??
      PixelAspectRatio.auto,
  customPixelAspectRatio:
      (json['customPixelAspectRatio'] as num?)?.toDouble() ?? 1.0,
  videoFilters:
      (json['videoFilters'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$VideoFilterEnumMap, e))
          .toList() ??
      const [],
  crtFilter: json['crtFilter'] == null
      ? const CrtFilterSettings()
      : _crtFilterFromJson(json['crtFilter']),
);

Map<String, dynamic> _$SettingsToJson(_Settings instance) => <String, dynamic>{
  'volume': instance.volume,
  'lowPassFilter': instance.lowPassFilter,
  'fastForwardSpeed': _$FastForwardSpeedEnumMap[instance.fastForwardSpeed]!,
  'stretch': instance.stretch,
  'showBorder': instance.showBorder,
  'showDebugOverlay': instance.showDebugOverlay,
  'logLevel': _$LogLevelEnumMap[instance.logLevel]!,
  'openTools': instance.openTools
      .map((e) => _$EmulatorToolEnumMap[e]!)
      .toList(),
  'scaling': _$ScalingEnumMap[instance.scaling]!,
  'autoSave': instance.autoSave,
  'autoSaveInterval': instance.autoSaveInterval,
  'autoLoad': instance.autoLoad,
  'bindings': instance.bindings,
  'bindingsVersion': instance.bindingsVersion,
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
  'renderer': _$RendererPreferenceEnumMap[instance.renderer]!,
  'rewind': instance.rewind,
  'pixelAspectRatio': _$PixelAspectRatioEnumMap[instance.pixelAspectRatio]!,
  'customPixelAspectRatio': instance.customPixelAspectRatio,
  'videoFilters': instance.videoFilters
      .map((e) => _$VideoFilterEnumMap[e]!)
      .toList(),
  'crtFilter': _crtFilterToJson(instance.crtFilter),
};

const _$FastForwardSpeedEnumMap = {
  FastForwardSpeed.x2: 'x2',
  FastForwardSpeed.x3: 'x3',
  FastForwardSpeed.x4: 'x4',
  FastForwardSpeed.max: 'max',
};

const _$LogLevelEnumMap = {
  LogLevel.debug: 'debug',
  LogLevel.info: 'info',
  LogLevel.warning: 'warning',
  LogLevel.error: 'error',
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

const _$RendererPreferenceEnumMap = {
  RendererPreference.auto: 'auto',
  RendererPreference.gpu: 'gpu',
  RendererPreference.cpu: 'cpu',
};

const _$PixelAspectRatioEnumMap = {
  PixelAspectRatio.auto: 'auto',
  PixelAspectRatio.ntsc: 'ntsc',
  PixelAspectRatio.pal: 'pal',
  PixelAspectRatio.square: 'square',
  PixelAspectRatio.stretch: 'stretch',
  PixelAspectRatio.custom: 'custom',
};

const _$VideoFilterEnumMap = {
  VideoFilter.none: 'none',
  VideoFilter.crt: 'crt',
  VideoFilter.smooth: 'smooth',
};

const _$EmulatorToolEnumMap = {
  EmulatorTool.display: 'display',
  EmulatorTool.tileViewer: 'tileViewer',
  EmulatorTool.cartridgeInfo: 'cartridgeInfo',
  EmulatorTool.apuDebug: 'apuDebug',
  EmulatorTool.debugger: 'debugger',
  EmulatorTool.executionLog: 'executionLog',
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
    r'9a7d402cb9889d3bd700820c24f4d0bf42356bc4';

abstract class _$SettingsController extends $Notifier<Settings> {
  Settings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Settings, Settings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Settings, Settings>,
              Settings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
