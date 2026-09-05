// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Settings {

 double get volume; bool get lowPassFilter; bool get swapDutyCycles;@JsonKey(toJson: _mixerToJson, fromJson: _mixerFromJson) MixerSettings get mixer; FastForwardSpeed get fastForwardSpeed; TurboSpeed get turboSpeed; bool get stretch; bool get showBorder; bool get showDebugOverlay; LogLevel get logLevel;@JsonKey(fromJson: openToolsFromJson) Set<EmulatorTool> get openTools; Scaling get scaling; bool get autoSave; int? get autoSaveInterval; bool get autoLoad;@JsonKey(fromJson: bindingsFromJson) List<Binding> get bindings; int get bindingsVersion;@JsonKey(fromJson: gamepadSlotsFromJson, toJson: gamepadSlotsToJson) Map<int, GamepadDeviceKey> get gamepadSlots;@JsonKey(fromJson: _lastRomPathFromJson) FilesystemFile? get lastRomPath; List<String> get recentRomPaths;@JsonKey(fromJson: _recentRomsFromJson) List<RomInfo> get recentRoms; bool get showTouchControls;@JsonKey(fromJson: narrowTouchInputConfigsFromJson) List<TouchInputConfig> get narrowTouchInputConfig;@JsonKey(fromJson: wideTouchInputConfigsFromJson) List<TouchInputConfig> get wideTouchInputConfig; Map<String, List<Breakpoint>> get breakpoints; Map<String, List<Cheat>> get cheats; Region? get region; ThemeMode get themeMode; RendererPreference get renderer; bool get rewind; PixelAspectRatio get pixelAspectRatio; double get customPixelAspectRatio; List<VideoFilter> get videoFilters;@JsonKey(toJson: _crtFilterToJson, fromJson: _crtFilterFromJson) CrtFilterSettings get crtFilter;@JsonKey(toJson: _overscanToJson, fromJson: _overscanFromJson) Overscan get overscan; NesPaletteId get paletteId;@JsonKey(toJson: _ntscPaletteToJson, fromJson: _ntscPaletteFromJson) NtscPaletteSettings get ntscPalette;
/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsCopyWith<Settings> get copyWith => _$SettingsCopyWithImpl<Settings>(this as Settings, _$identity);

  /// Serializes this Settings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Settings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Settings&&(identical(other.volume, _this.volume) || other.volume == _this.volume)&&(identical(other.lowPassFilter, _this.lowPassFilter) || other.lowPassFilter == _this.lowPassFilter)&&(identical(other.swapDutyCycles, _this.swapDutyCycles) || other.swapDutyCycles == _this.swapDutyCycles)&&(identical(other.mixer, _this.mixer) || other.mixer == _this.mixer)&&(identical(other.fastForwardSpeed, _this.fastForwardSpeed) || other.fastForwardSpeed == _this.fastForwardSpeed)&&(identical(other.turboSpeed, _this.turboSpeed) || other.turboSpeed == _this.turboSpeed)&&(identical(other.stretch, _this.stretch) || other.stretch == _this.stretch)&&(identical(other.showBorder, _this.showBorder) || other.showBorder == _this.showBorder)&&(identical(other.showDebugOverlay, _this.showDebugOverlay) || other.showDebugOverlay == _this.showDebugOverlay)&&(identical(other.logLevel, _this.logLevel) || other.logLevel == _this.logLevel)&&const DeepCollectionEquality().equals(other.openTools, _this.openTools)&&(identical(other.scaling, _this.scaling) || other.scaling == _this.scaling)&&(identical(other.autoSave, _this.autoSave) || other.autoSave == _this.autoSave)&&(identical(other.autoSaveInterval, _this.autoSaveInterval) || other.autoSaveInterval == _this.autoSaveInterval)&&(identical(other.autoLoad, _this.autoLoad) || other.autoLoad == _this.autoLoad)&&const DeepCollectionEquality().equals(other.bindings, _this.bindings)&&(identical(other.bindingsVersion, _this.bindingsVersion) || other.bindingsVersion == _this.bindingsVersion)&&const DeepCollectionEquality().equals(other.gamepadSlots, _this.gamepadSlots)&&(identical(other.lastRomPath, _this.lastRomPath) || other.lastRomPath == _this.lastRomPath)&&const DeepCollectionEquality().equals(other.recentRomPaths, _this.recentRomPaths)&&const DeepCollectionEquality().equals(other.recentRoms, _this.recentRoms)&&(identical(other.showTouchControls, _this.showTouchControls) || other.showTouchControls == _this.showTouchControls)&&const DeepCollectionEquality().equals(other.narrowTouchInputConfig, _this.narrowTouchInputConfig)&&const DeepCollectionEquality().equals(other.wideTouchInputConfig, _this.wideTouchInputConfig)&&const DeepCollectionEquality().equals(other.breakpoints, _this.breakpoints)&&const DeepCollectionEquality().equals(other.cheats, _this.cheats)&&(identical(other.region, _this.region) || other.region == _this.region)&&(identical(other.themeMode, _this.themeMode) || other.themeMode == _this.themeMode)&&(identical(other.renderer, _this.renderer) || other.renderer == _this.renderer)&&(identical(other.rewind, _this.rewind) || other.rewind == _this.rewind)&&(identical(other.pixelAspectRatio, _this.pixelAspectRatio) || other.pixelAspectRatio == _this.pixelAspectRatio)&&(identical(other.customPixelAspectRatio, _this.customPixelAspectRatio) || other.customPixelAspectRatio == _this.customPixelAspectRatio)&&const DeepCollectionEquality().equals(other.videoFilters, _this.videoFilters)&&(identical(other.crtFilter, _this.crtFilter) || other.crtFilter == _this.crtFilter)&&(identical(other.overscan, _this.overscan) || other.overscan == _this.overscan)&&(identical(other.paletteId, _this.paletteId) || other.paletteId == _this.paletteId)&&(identical(other.ntscPalette, _this.ntscPalette) || other.ntscPalette == _this.ntscPalette));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Settings;
  return Object.hashAll([runtimeType,_this.volume,_this.lowPassFilter,_this.swapDutyCycles,_this.mixer,_this.fastForwardSpeed,_this.turboSpeed,_this.stretch,_this.showBorder,_this.showDebugOverlay,_this.logLevel,const DeepCollectionEquality().hash(_this.openTools),_this.scaling,_this.autoSave,_this.autoSaveInterval,_this.autoLoad,const DeepCollectionEquality().hash(_this.bindings),_this.bindingsVersion,const DeepCollectionEquality().hash(_this.gamepadSlots),_this.lastRomPath,const DeepCollectionEquality().hash(_this.recentRomPaths),const DeepCollectionEquality().hash(_this.recentRoms),_this.showTouchControls,const DeepCollectionEquality().hash(_this.narrowTouchInputConfig),const DeepCollectionEquality().hash(_this.wideTouchInputConfig),const DeepCollectionEquality().hash(_this.breakpoints),const DeepCollectionEquality().hash(_this.cheats),_this.region,_this.themeMode,_this.renderer,_this.rewind,_this.pixelAspectRatio,_this.customPixelAspectRatio,const DeepCollectionEquality().hash(_this.videoFilters),_this.crtFilter,_this.overscan,_this.paletteId,_this.ntscPalette]);
}

@override
String toString() {
  final _this = this as Settings;
  return 'Settings(volume: ${_this.volume}, lowPassFilter: ${_this.lowPassFilter}, swapDutyCycles: ${_this.swapDutyCycles}, mixer: ${_this.mixer}, fastForwardSpeed: ${_this.fastForwardSpeed}, turboSpeed: ${_this.turboSpeed}, stretch: ${_this.stretch}, showBorder: ${_this.showBorder}, showDebugOverlay: ${_this.showDebugOverlay}, logLevel: ${_this.logLevel}, openTools: ${_this.openTools}, scaling: ${_this.scaling}, autoSave: ${_this.autoSave}, autoSaveInterval: ${_this.autoSaveInterval}, autoLoad: ${_this.autoLoad}, bindings: ${_this.bindings}, bindingsVersion: ${_this.bindingsVersion}, gamepadSlots: ${_this.gamepadSlots}, lastRomPath: ${_this.lastRomPath}, recentRomPaths: ${_this.recentRomPaths}, recentRoms: ${_this.recentRoms}, showTouchControls: ${_this.showTouchControls}, narrowTouchInputConfig: ${_this.narrowTouchInputConfig}, wideTouchInputConfig: ${_this.wideTouchInputConfig}, breakpoints: ${_this.breakpoints}, cheats: ${_this.cheats}, region: ${_this.region}, themeMode: ${_this.themeMode}, renderer: ${_this.renderer}, rewind: ${_this.rewind}, pixelAspectRatio: ${_this.pixelAspectRatio}, customPixelAspectRatio: ${_this.customPixelAspectRatio}, videoFilters: ${_this.videoFilters}, crtFilter: ${_this.crtFilter}, overscan: ${_this.overscan}, paletteId: ${_this.paletteId}, ntscPalette: ${_this.ntscPalette})';
}


}

/// @nodoc
abstract mixin class $SettingsCopyWith<$Res>  {
  factory $SettingsCopyWith(Settings value, $Res Function(Settings) _then) = _$SettingsCopyWithImpl;
@useResult
$Res call({
 double volume, bool lowPassFilter, bool swapDutyCycles,@JsonKey(toJson: _mixerToJson, fromJson: _mixerFromJson) MixerSettings mixer, FastForwardSpeed fastForwardSpeed, TurboSpeed turboSpeed, bool stretch, bool showBorder, bool showDebugOverlay, LogLevel logLevel,@JsonKey(fromJson: openToolsFromJson) Set<EmulatorTool> openTools, Scaling scaling, bool autoSave, int? autoSaveInterval, bool autoLoad,@JsonKey(fromJson: bindingsFromJson) List<Binding> bindings, int bindingsVersion,@JsonKey(fromJson: gamepadSlotsFromJson, toJson: gamepadSlotsToJson) Map<int, GamepadDeviceKey> gamepadSlots,@JsonKey(fromJson: _lastRomPathFromJson) FilesystemFile? lastRomPath, List<String> recentRomPaths,@JsonKey(fromJson: _recentRomsFromJson) List<RomInfo> recentRoms, bool showTouchControls,@JsonKey(fromJson: narrowTouchInputConfigsFromJson) List<TouchInputConfig> narrowTouchInputConfig,@JsonKey(fromJson: wideTouchInputConfigsFromJson) List<TouchInputConfig> wideTouchInputConfig, Map<String, List<Breakpoint>> breakpoints, Map<String, List<Cheat>> cheats, Region? region, ThemeMode themeMode, RendererPreference renderer, bool rewind, PixelAspectRatio pixelAspectRatio, double customPixelAspectRatio, List<VideoFilter> videoFilters,@JsonKey(toJson: _crtFilterToJson, fromJson: _crtFilterFromJson) CrtFilterSettings crtFilter,@JsonKey(toJson: _overscanToJson, fromJson: _overscanFromJson) Overscan overscan, NesPaletteId paletteId,@JsonKey(toJson: _ntscPaletteToJson, fromJson: _ntscPaletteFromJson) NtscPaletteSettings ntscPalette
});


$MixerSettingsCopyWith<$Res> get mixer;$CrtFilterSettingsCopyWith<$Res> get crtFilter;$OverscanCopyWith<$Res> get overscan;$NtscPaletteSettingsCopyWith<$Res> get ntscPalette;

}
/// @nodoc
class _$SettingsCopyWithImpl<$Res>
    implements $SettingsCopyWith<$Res> {
  _$SettingsCopyWithImpl(this._self, this._then);

  final Settings _self;
  final $Res Function(Settings) _then;

/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? volume = null,Object? lowPassFilter = null,Object? swapDutyCycles = null,Object? mixer = null,Object? fastForwardSpeed = null,Object? turboSpeed = null,Object? stretch = null,Object? showBorder = null,Object? showDebugOverlay = null,Object? logLevel = null,Object? openTools = null,Object? scaling = null,Object? autoSave = null,Object? autoSaveInterval = freezed,Object? autoLoad = null,Object? bindings = null,Object? bindingsVersion = null,Object? gamepadSlots = null,Object? lastRomPath = freezed,Object? recentRomPaths = null,Object? recentRoms = null,Object? showTouchControls = null,Object? narrowTouchInputConfig = null,Object? wideTouchInputConfig = null,Object? breakpoints = null,Object? cheats = null,Object? region = freezed,Object? themeMode = null,Object? renderer = null,Object? rewind = null,Object? pixelAspectRatio = null,Object? customPixelAspectRatio = null,Object? videoFilters = null,Object? crtFilter = null,Object? overscan = null,Object? paletteId = null,Object? ntscPalette = null,}) {
  return _then(Settings(
volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,lowPassFilter: null == lowPassFilter ? _self.lowPassFilter : lowPassFilter // ignore: cast_nullable_to_non_nullable
as bool,swapDutyCycles: null == swapDutyCycles ? _self.swapDutyCycles : swapDutyCycles // ignore: cast_nullable_to_non_nullable
as bool,mixer: null == mixer ? _self.mixer : mixer // ignore: cast_nullable_to_non_nullable
as MixerSettings,fastForwardSpeed: null == fastForwardSpeed ? _self.fastForwardSpeed : fastForwardSpeed // ignore: cast_nullable_to_non_nullable
as FastForwardSpeed,turboSpeed: null == turboSpeed ? _self.turboSpeed : turboSpeed // ignore: cast_nullable_to_non_nullable
as TurboSpeed,stretch: null == stretch ? _self.stretch : stretch // ignore: cast_nullable_to_non_nullable
as bool,showBorder: null == showBorder ? _self.showBorder : showBorder // ignore: cast_nullable_to_non_nullable
as bool,showDebugOverlay: null == showDebugOverlay ? _self.showDebugOverlay : showDebugOverlay // ignore: cast_nullable_to_non_nullable
as bool,logLevel: null == logLevel ? _self.logLevel : logLevel // ignore: cast_nullable_to_non_nullable
as LogLevel,openTools: null == openTools ? _self.openTools : openTools // ignore: cast_nullable_to_non_nullable
as Set<EmulatorTool>,scaling: null == scaling ? _self.scaling : scaling // ignore: cast_nullable_to_non_nullable
as Scaling,autoSave: null == autoSave ? _self.autoSave : autoSave // ignore: cast_nullable_to_non_nullable
as bool,autoSaveInterval: freezed == autoSaveInterval ? _self.autoSaveInterval : autoSaveInterval // ignore: cast_nullable_to_non_nullable
as int?,autoLoad: null == autoLoad ? _self.autoLoad : autoLoad // ignore: cast_nullable_to_non_nullable
as bool,bindings: null == bindings ? _self.bindings : bindings // ignore: cast_nullable_to_non_nullable
as List<Binding>,bindingsVersion: null == bindingsVersion ? _self.bindingsVersion : bindingsVersion // ignore: cast_nullable_to_non_nullable
as int,gamepadSlots: null == gamepadSlots ? _self.gamepadSlots : gamepadSlots // ignore: cast_nullable_to_non_nullable
as Map<int, GamepadDeviceKey>,lastRomPath: freezed == lastRomPath ? _self.lastRomPath : lastRomPath // ignore: cast_nullable_to_non_nullable
as FilesystemFile?,recentRomPaths: null == recentRomPaths ? _self.recentRomPaths : recentRomPaths // ignore: cast_nullable_to_non_nullable
as List<String>,recentRoms: null == recentRoms ? _self.recentRoms : recentRoms // ignore: cast_nullable_to_non_nullable
as List<RomInfo>,showTouchControls: null == showTouchControls ? _self.showTouchControls : showTouchControls // ignore: cast_nullable_to_non_nullable
as bool,narrowTouchInputConfig: null == narrowTouchInputConfig ? _self.narrowTouchInputConfig : narrowTouchInputConfig // ignore: cast_nullable_to_non_nullable
as List<TouchInputConfig>,wideTouchInputConfig: null == wideTouchInputConfig ? _self.wideTouchInputConfig : wideTouchInputConfig // ignore: cast_nullable_to_non_nullable
as List<TouchInputConfig>,breakpoints: null == breakpoints ? _self.breakpoints : breakpoints // ignore: cast_nullable_to_non_nullable
as Map<String, List<Breakpoint>>,cheats: null == cheats ? _self.cheats : cheats // ignore: cast_nullable_to_non_nullable
as Map<String, List<Cheat>>,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as Region?,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemeMode,renderer: null == renderer ? _self.renderer : renderer // ignore: cast_nullable_to_non_nullable
as RendererPreference,rewind: null == rewind ? _self.rewind : rewind // ignore: cast_nullable_to_non_nullable
as bool,pixelAspectRatio: null == pixelAspectRatio ? _self.pixelAspectRatio : pixelAspectRatio // ignore: cast_nullable_to_non_nullable
as PixelAspectRatio,customPixelAspectRatio: null == customPixelAspectRatio ? _self.customPixelAspectRatio : customPixelAspectRatio // ignore: cast_nullable_to_non_nullable
as double,videoFilters: null == videoFilters ? _self.videoFilters : videoFilters // ignore: cast_nullable_to_non_nullable
as List<VideoFilter>,crtFilter: null == crtFilter ? _self.crtFilter : crtFilter // ignore: cast_nullable_to_non_nullable
as CrtFilterSettings,overscan: null == overscan ? _self.overscan : overscan // ignore: cast_nullable_to_non_nullable
as Overscan,paletteId: null == paletteId ? _self.paletteId : paletteId // ignore: cast_nullable_to_non_nullable
as NesPaletteId,ntscPalette: null == ntscPalette ? _self.ntscPalette : ntscPalette // ignore: cast_nullable_to_non_nullable
as NtscPaletteSettings,
  ));
}
/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MixerSettingsCopyWith<$Res> get mixer {
  
  return $MixerSettingsCopyWith<$Res>(_self.mixer, (value) {
    return _then(_self.copyWith(mixer: value));
  });
}/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CrtFilterSettingsCopyWith<$Res> get crtFilter {
  
  return $CrtFilterSettingsCopyWith<$Res>(_self.crtFilter, (value) {
    return _then(_self.copyWith(crtFilter: value));
  });
}/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OverscanCopyWith<$Res> get overscan {
  
  return $OverscanCopyWith<$Res>(_self.overscan, (value) {
    return _then(_self.copyWith(overscan: value));
  });
}/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NtscPaletteSettingsCopyWith<$Res> get ntscPalette {
  
  return $NtscPaletteSettingsCopyWith<$Res>(_self.ntscPalette, (value) {
    return _then(_self.copyWith(ntscPalette: value));
  });
}
}


/// Adds pattern-matching-related methods to [Settings].
extension SettingsPatterns on Settings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Settings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Settings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Settings value)  $default,){
final _that = this;
switch (_that) {
case _Settings():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Settings value)?  $default,){
final _that = this;
switch (_that) {
case _Settings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double volume,  bool lowPassFilter,  bool swapDutyCycles, @JsonKey(toJson: _mixerToJson, fromJson: _mixerFromJson)  MixerSettings mixer,  FastForwardSpeed fastForwardSpeed,  TurboSpeed turboSpeed,  bool stretch,  bool showBorder,  bool showDebugOverlay,  LogLevel logLevel, @JsonKey(fromJson: openToolsFromJson)  Set<EmulatorTool> openTools,  Scaling scaling,  bool autoSave,  int? autoSaveInterval,  bool autoLoad, @JsonKey(fromJson: bindingsFromJson)  List<Binding> bindings,  int bindingsVersion, @JsonKey(fromJson: gamepadSlotsFromJson, toJson: gamepadSlotsToJson)  Map<int, GamepadDeviceKey> gamepadSlots, @JsonKey(fromJson: _lastRomPathFromJson)  FilesystemFile? lastRomPath,  List<String> recentRomPaths, @JsonKey(fromJson: _recentRomsFromJson)  List<RomInfo> recentRoms,  bool showTouchControls, @JsonKey(fromJson: narrowTouchInputConfigsFromJson)  List<TouchInputConfig> narrowTouchInputConfig, @JsonKey(fromJson: wideTouchInputConfigsFromJson)  List<TouchInputConfig> wideTouchInputConfig,  Map<String, List<Breakpoint>> breakpoints,  Map<String, List<Cheat>> cheats,  Region? region,  ThemeMode themeMode,  RendererPreference renderer,  bool rewind,  PixelAspectRatio pixelAspectRatio,  double customPixelAspectRatio,  List<VideoFilter> videoFilters, @JsonKey(toJson: _crtFilterToJson, fromJson: _crtFilterFromJson)  CrtFilterSettings crtFilter, @JsonKey(toJson: _overscanToJson, fromJson: _overscanFromJson)  Overscan overscan,  NesPaletteId paletteId, @JsonKey(toJson: _ntscPaletteToJson, fromJson: _ntscPaletteFromJson)  NtscPaletteSettings ntscPalette)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Settings() when $default != null:
return $default(_that.volume,_that.lowPassFilter,_that.swapDutyCycles,_that.mixer,_that.fastForwardSpeed,_that.turboSpeed,_that.stretch,_that.showBorder,_that.showDebugOverlay,_that.logLevel,_that.openTools,_that.scaling,_that.autoSave,_that.autoSaveInterval,_that.autoLoad,_that.bindings,_that.bindingsVersion,_that.gamepadSlots,_that.lastRomPath,_that.recentRomPaths,_that.recentRoms,_that.showTouchControls,_that.narrowTouchInputConfig,_that.wideTouchInputConfig,_that.breakpoints,_that.cheats,_that.region,_that.themeMode,_that.renderer,_that.rewind,_that.pixelAspectRatio,_that.customPixelAspectRatio,_that.videoFilters,_that.crtFilter,_that.overscan,_that.paletteId,_that.ntscPalette);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double volume,  bool lowPassFilter,  bool swapDutyCycles, @JsonKey(toJson: _mixerToJson, fromJson: _mixerFromJson)  MixerSettings mixer,  FastForwardSpeed fastForwardSpeed,  TurboSpeed turboSpeed,  bool stretch,  bool showBorder,  bool showDebugOverlay,  LogLevel logLevel, @JsonKey(fromJson: openToolsFromJson)  Set<EmulatorTool> openTools,  Scaling scaling,  bool autoSave,  int? autoSaveInterval,  bool autoLoad, @JsonKey(fromJson: bindingsFromJson)  List<Binding> bindings,  int bindingsVersion, @JsonKey(fromJson: gamepadSlotsFromJson, toJson: gamepadSlotsToJson)  Map<int, GamepadDeviceKey> gamepadSlots, @JsonKey(fromJson: _lastRomPathFromJson)  FilesystemFile? lastRomPath,  List<String> recentRomPaths, @JsonKey(fromJson: _recentRomsFromJson)  List<RomInfo> recentRoms,  bool showTouchControls, @JsonKey(fromJson: narrowTouchInputConfigsFromJson)  List<TouchInputConfig> narrowTouchInputConfig, @JsonKey(fromJson: wideTouchInputConfigsFromJson)  List<TouchInputConfig> wideTouchInputConfig,  Map<String, List<Breakpoint>> breakpoints,  Map<String, List<Cheat>> cheats,  Region? region,  ThemeMode themeMode,  RendererPreference renderer,  bool rewind,  PixelAspectRatio pixelAspectRatio,  double customPixelAspectRatio,  List<VideoFilter> videoFilters, @JsonKey(toJson: _crtFilterToJson, fromJson: _crtFilterFromJson)  CrtFilterSettings crtFilter, @JsonKey(toJson: _overscanToJson, fromJson: _overscanFromJson)  Overscan overscan,  NesPaletteId paletteId, @JsonKey(toJson: _ntscPaletteToJson, fromJson: _ntscPaletteFromJson)  NtscPaletteSettings ntscPalette)  $default,) {final _that = this;
switch (_that) {
case _Settings():
return $default(_that.volume,_that.lowPassFilter,_that.swapDutyCycles,_that.mixer,_that.fastForwardSpeed,_that.turboSpeed,_that.stretch,_that.showBorder,_that.showDebugOverlay,_that.logLevel,_that.openTools,_that.scaling,_that.autoSave,_that.autoSaveInterval,_that.autoLoad,_that.bindings,_that.bindingsVersion,_that.gamepadSlots,_that.lastRomPath,_that.recentRomPaths,_that.recentRoms,_that.showTouchControls,_that.narrowTouchInputConfig,_that.wideTouchInputConfig,_that.breakpoints,_that.cheats,_that.region,_that.themeMode,_that.renderer,_that.rewind,_that.pixelAspectRatio,_that.customPixelAspectRatio,_that.videoFilters,_that.crtFilter,_that.overscan,_that.paletteId,_that.ntscPalette);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double volume,  bool lowPassFilter,  bool swapDutyCycles, @JsonKey(toJson: _mixerToJson, fromJson: _mixerFromJson)  MixerSettings mixer,  FastForwardSpeed fastForwardSpeed,  TurboSpeed turboSpeed,  bool stretch,  bool showBorder,  bool showDebugOverlay,  LogLevel logLevel, @JsonKey(fromJson: openToolsFromJson)  Set<EmulatorTool> openTools,  Scaling scaling,  bool autoSave,  int? autoSaveInterval,  bool autoLoad, @JsonKey(fromJson: bindingsFromJson)  List<Binding> bindings,  int bindingsVersion, @JsonKey(fromJson: gamepadSlotsFromJson, toJson: gamepadSlotsToJson)  Map<int, GamepadDeviceKey> gamepadSlots, @JsonKey(fromJson: _lastRomPathFromJson)  FilesystemFile? lastRomPath,  List<String> recentRomPaths, @JsonKey(fromJson: _recentRomsFromJson)  List<RomInfo> recentRoms,  bool showTouchControls, @JsonKey(fromJson: narrowTouchInputConfigsFromJson)  List<TouchInputConfig> narrowTouchInputConfig, @JsonKey(fromJson: wideTouchInputConfigsFromJson)  List<TouchInputConfig> wideTouchInputConfig,  Map<String, List<Breakpoint>> breakpoints,  Map<String, List<Cheat>> cheats,  Region? region,  ThemeMode themeMode,  RendererPreference renderer,  bool rewind,  PixelAspectRatio pixelAspectRatio,  double customPixelAspectRatio,  List<VideoFilter> videoFilters, @JsonKey(toJson: _crtFilterToJson, fromJson: _crtFilterFromJson)  CrtFilterSettings crtFilter, @JsonKey(toJson: _overscanToJson, fromJson: _overscanFromJson)  Overscan overscan,  NesPaletteId paletteId, @JsonKey(toJson: _ntscPaletteToJson, fromJson: _ntscPaletteFromJson)  NtscPaletteSettings ntscPalette)?  $default,) {final _that = this;
switch (_that) {
case _Settings() when $default != null:
return $default(_that.volume,_that.lowPassFilter,_that.swapDutyCycles,_that.mixer,_that.fastForwardSpeed,_that.turboSpeed,_that.stretch,_that.showBorder,_that.showDebugOverlay,_that.logLevel,_that.openTools,_that.scaling,_that.autoSave,_that.autoSaveInterval,_that.autoLoad,_that.bindings,_that.bindingsVersion,_that.gamepadSlots,_that.lastRomPath,_that.recentRomPaths,_that.recentRoms,_that.showTouchControls,_that.narrowTouchInputConfig,_that.wideTouchInputConfig,_that.breakpoints,_that.cheats,_that.region,_that.themeMode,_that.renderer,_that.rewind,_that.pixelAspectRatio,_that.customPixelAspectRatio,_that.videoFilters,_that.crtFilter,_that.overscan,_that.paletteId,_that.ntscPalette);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Settings implements Settings {
   _Settings({this.volume = 1.0, this.lowPassFilter = false, this.swapDutyCycles = false, @JsonKey(toJson: _mixerToJson, fromJson: _mixerFromJson) this.mixer = const MixerSettings(), this.fastForwardSpeed = FastForwardSpeed.x2, this.turboSpeed = TurboSpeed.x1, this.stretch = true, this.showBorder = false, this.showDebugOverlay = false, this.logLevel = LogLevel.info, @JsonKey(fromJson: openToolsFromJson)  Set<EmulatorTool> openTools = const <EmulatorTool>{}, this.scaling = Scaling.autoSmooth, this.autoSave = true, this.autoSaveInterval = 1, this.autoLoad = true, @JsonKey(fromJson: bindingsFromJson)  List<Binding> bindings = const [], this.bindingsVersion = 3, @JsonKey(fromJson: gamepadSlotsFromJson, toJson: gamepadSlotsToJson)  Map<int, GamepadDeviceKey> gamepadSlots = const <int, GamepadDeviceKey>{}, @JsonKey(fromJson: _lastRomPathFromJson) this.lastRomPath = null,  List<String> recentRomPaths = const [], @JsonKey(fromJson: _recentRomsFromJson)  List<RomInfo> recentRoms = const [], this.showTouchControls = false, @JsonKey(fromJson: narrowTouchInputConfigsFromJson)  List<TouchInputConfig> narrowTouchInputConfig = const [], @JsonKey(fromJson: wideTouchInputConfigsFromJson)  List<TouchInputConfig> wideTouchInputConfig = const [],  Map<String, List<Breakpoint>> breakpoints = const {},  Map<String, List<Cheat>> cheats = const {}, this.region = null, this.themeMode = ThemeMode.system, this.renderer = RendererPreference.auto, this.rewind = true, this.pixelAspectRatio = PixelAspectRatio.auto, this.customPixelAspectRatio = 1.0,  List<VideoFilter> videoFilters = const [], @JsonKey(toJson: _crtFilterToJson, fromJson: _crtFilterFromJson) this.crtFilter = const CrtFilterSettings(), @JsonKey(toJson: _overscanToJson, fromJson: _overscanFromJson) this.overscan = const Overscan(), this.paletteId = NesPaletteId.defaultPalette, @JsonKey(toJson: _ntscPaletteToJson, fromJson: _ntscPaletteFromJson) this.ntscPalette = const NtscPaletteSettings()}): _openTools = openTools,_bindings = bindings,_gamepadSlots = gamepadSlots,_recentRomPaths = recentRomPaths,_recentRoms = recentRoms,_narrowTouchInputConfig = narrowTouchInputConfig,_wideTouchInputConfig = wideTouchInputConfig,_breakpoints = breakpoints,_cheats = cheats,_videoFilters = videoFilters;
  factory _Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);

@override@JsonKey() final  double volume;
@override@JsonKey() final  bool lowPassFilter;
@override@JsonKey() final  bool swapDutyCycles;
@override@JsonKey(toJson: _mixerToJson, fromJson: _mixerFromJson) final  MixerSettings mixer;
@override@JsonKey() final  FastForwardSpeed fastForwardSpeed;
@override@JsonKey() final  TurboSpeed turboSpeed;
@override@JsonKey() final  bool stretch;
@override@JsonKey() final  bool showBorder;
@override@JsonKey() final  bool showDebugOverlay;
@override@JsonKey() final  LogLevel logLevel;
 final  Set<EmulatorTool> _openTools;
@override@JsonKey(fromJson: openToolsFromJson) Set<EmulatorTool> get openTools {
  if (_openTools is EqualUnmodifiableSetView) return _openTools;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_openTools);
}

@override@JsonKey() final  Scaling scaling;
@override@JsonKey() final  bool autoSave;
@override@JsonKey() final  int? autoSaveInterval;
@override@JsonKey() final  bool autoLoad;
 final  List<Binding> _bindings;
@override@JsonKey(fromJson: bindingsFromJson) List<Binding> get bindings {
  if (_bindings is EqualUnmodifiableListView) return _bindings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bindings);
}

@override@JsonKey() final  int bindingsVersion;
 final  Map<int, GamepadDeviceKey> _gamepadSlots;
@override@JsonKey(fromJson: gamepadSlotsFromJson, toJson: gamepadSlotsToJson) Map<int, GamepadDeviceKey> get gamepadSlots {
  if (_gamepadSlots is EqualUnmodifiableMapView) return _gamepadSlots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_gamepadSlots);
}

@override@JsonKey(fromJson: _lastRomPathFromJson) final  FilesystemFile? lastRomPath;
 final  List<String> _recentRomPaths;
@override@JsonKey() List<String> get recentRomPaths {
  if (_recentRomPaths is EqualUnmodifiableListView) return _recentRomPaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentRomPaths);
}

 final  List<RomInfo> _recentRoms;
@override@JsonKey(fromJson: _recentRomsFromJson) List<RomInfo> get recentRoms {
  if (_recentRoms is EqualUnmodifiableListView) return _recentRoms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentRoms);
}

@override@JsonKey() final  bool showTouchControls;
 final  List<TouchInputConfig> _narrowTouchInputConfig;
@override@JsonKey(fromJson: narrowTouchInputConfigsFromJson) List<TouchInputConfig> get narrowTouchInputConfig {
  if (_narrowTouchInputConfig is EqualUnmodifiableListView) return _narrowTouchInputConfig;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_narrowTouchInputConfig);
}

 final  List<TouchInputConfig> _wideTouchInputConfig;
@override@JsonKey(fromJson: wideTouchInputConfigsFromJson) List<TouchInputConfig> get wideTouchInputConfig {
  if (_wideTouchInputConfig is EqualUnmodifiableListView) return _wideTouchInputConfig;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_wideTouchInputConfig);
}

 final  Map<String, List<Breakpoint>> _breakpoints;
@override@JsonKey() Map<String, List<Breakpoint>> get breakpoints {
  if (_breakpoints is EqualUnmodifiableMapView) return _breakpoints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_breakpoints);
}

 final  Map<String, List<Cheat>> _cheats;
@override@JsonKey() Map<String, List<Cheat>> get cheats {
  if (_cheats is EqualUnmodifiableMapView) return _cheats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_cheats);
}

@override@JsonKey() final  Region? region;
@override@JsonKey() final  ThemeMode themeMode;
@override@JsonKey() final  RendererPreference renderer;
@override@JsonKey() final  bool rewind;
@override@JsonKey() final  PixelAspectRatio pixelAspectRatio;
@override@JsonKey() final  double customPixelAspectRatio;
 final  List<VideoFilter> _videoFilters;
@override@JsonKey() List<VideoFilter> get videoFilters {
  if (_videoFilters is EqualUnmodifiableListView) return _videoFilters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_videoFilters);
}

@override@JsonKey(toJson: _crtFilterToJson, fromJson: _crtFilterFromJson) final  CrtFilterSettings crtFilter;
@override@JsonKey(toJson: _overscanToJson, fromJson: _overscanFromJson) final  Overscan overscan;
@override@JsonKey() final  NesPaletteId paletteId;
@override@JsonKey(toJson: _ntscPaletteToJson, fromJson: _ntscPaletteFromJson) final  NtscPaletteSettings ntscPalette;

/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingsCopyWith<_Settings> get copyWith => __$SettingsCopyWithImpl<_Settings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SettingsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Settings&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.lowPassFilter, lowPassFilter) || other.lowPassFilter == lowPassFilter)&&(identical(other.swapDutyCycles, swapDutyCycles) || other.swapDutyCycles == swapDutyCycles)&&(identical(other.mixer, mixer) || other.mixer == mixer)&&(identical(other.fastForwardSpeed, fastForwardSpeed) || other.fastForwardSpeed == fastForwardSpeed)&&(identical(other.turboSpeed, turboSpeed) || other.turboSpeed == turboSpeed)&&(identical(other.stretch, stretch) || other.stretch == stretch)&&(identical(other.showBorder, showBorder) || other.showBorder == showBorder)&&(identical(other.showDebugOverlay, showDebugOverlay) || other.showDebugOverlay == showDebugOverlay)&&(identical(other.logLevel, logLevel) || other.logLevel == logLevel)&&const DeepCollectionEquality().equals(other.openTools, _openTools)&&(identical(other.scaling, scaling) || other.scaling == scaling)&&(identical(other.autoSave, autoSave) || other.autoSave == autoSave)&&(identical(other.autoSaveInterval, autoSaveInterval) || other.autoSaveInterval == autoSaveInterval)&&(identical(other.autoLoad, autoLoad) || other.autoLoad == autoLoad)&&const DeepCollectionEquality().equals(other.bindings, _bindings)&&(identical(other.bindingsVersion, bindingsVersion) || other.bindingsVersion == bindingsVersion)&&const DeepCollectionEquality().equals(other.gamepadSlots, _gamepadSlots)&&(identical(other.lastRomPath, lastRomPath) || other.lastRomPath == lastRomPath)&&const DeepCollectionEquality().equals(other.recentRomPaths, _recentRomPaths)&&const DeepCollectionEquality().equals(other.recentRoms, _recentRoms)&&(identical(other.showTouchControls, showTouchControls) || other.showTouchControls == showTouchControls)&&const DeepCollectionEquality().equals(other.narrowTouchInputConfig, _narrowTouchInputConfig)&&const DeepCollectionEquality().equals(other.wideTouchInputConfig, _wideTouchInputConfig)&&const DeepCollectionEquality().equals(other.breakpoints, _breakpoints)&&const DeepCollectionEquality().equals(other.cheats, _cheats)&&(identical(other.region, region) || other.region == region)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.renderer, renderer) || other.renderer == renderer)&&(identical(other.rewind, rewind) || other.rewind == rewind)&&(identical(other.pixelAspectRatio, pixelAspectRatio) || other.pixelAspectRatio == pixelAspectRatio)&&(identical(other.customPixelAspectRatio, customPixelAspectRatio) || other.customPixelAspectRatio == customPixelAspectRatio)&&const DeepCollectionEquality().equals(other.videoFilters, _videoFilters)&&(identical(other.crtFilter, crtFilter) || other.crtFilter == crtFilter)&&(identical(other.overscan, overscan) || other.overscan == overscan)&&(identical(other.paletteId, paletteId) || other.paletteId == paletteId)&&(identical(other.ntscPalette, ntscPalette) || other.ntscPalette == ntscPalette));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,volume,lowPassFilter,swapDutyCycles,mixer,fastForwardSpeed,turboSpeed,stretch,showBorder,showDebugOverlay,logLevel,const DeepCollectionEquality().hash(_openTools),scaling,autoSave,autoSaveInterval,autoLoad,const DeepCollectionEquality().hash(_bindings),bindingsVersion,const DeepCollectionEquality().hash(_gamepadSlots),lastRomPath,const DeepCollectionEquality().hash(_recentRomPaths),const DeepCollectionEquality().hash(_recentRoms),showTouchControls,const DeepCollectionEquality().hash(_narrowTouchInputConfig),const DeepCollectionEquality().hash(_wideTouchInputConfig),const DeepCollectionEquality().hash(_breakpoints),const DeepCollectionEquality().hash(_cheats),region,themeMode,renderer,rewind,pixelAspectRatio,customPixelAspectRatio,const DeepCollectionEquality().hash(_videoFilters),crtFilter,overscan,paletteId,ntscPalette]);
}

@override
String toString() {
    return 'Settings(volume: $volume, lowPassFilter: $lowPassFilter, swapDutyCycles: $swapDutyCycles, mixer: $mixer, fastForwardSpeed: $fastForwardSpeed, turboSpeed: $turboSpeed, stretch: $stretch, showBorder: $showBorder, showDebugOverlay: $showDebugOverlay, logLevel: $logLevel, openTools: $openTools, scaling: $scaling, autoSave: $autoSave, autoSaveInterval: $autoSaveInterval, autoLoad: $autoLoad, bindings: $bindings, bindingsVersion: $bindingsVersion, gamepadSlots: $gamepadSlots, lastRomPath: $lastRomPath, recentRomPaths: $recentRomPaths, recentRoms: $recentRoms, showTouchControls: $showTouchControls, narrowTouchInputConfig: $narrowTouchInputConfig, wideTouchInputConfig: $wideTouchInputConfig, breakpoints: $breakpoints, cheats: $cheats, region: $region, themeMode: $themeMode, renderer: $renderer, rewind: $rewind, pixelAspectRatio: $pixelAspectRatio, customPixelAspectRatio: $customPixelAspectRatio, videoFilters: $videoFilters, crtFilter: $crtFilter, overscan: $overscan, paletteId: $paletteId, ntscPalette: $ntscPalette)';
}


}

/// @nodoc
abstract mixin class _$SettingsCopyWith<$Res> implements $SettingsCopyWith<$Res> {
  factory _$SettingsCopyWith(_Settings value, $Res Function(_Settings) _then) = __$SettingsCopyWithImpl;
@override @useResult
$Res call({
 double volume, bool lowPassFilter, bool swapDutyCycles,@JsonKey(toJson: _mixerToJson, fromJson: _mixerFromJson) MixerSettings mixer, FastForwardSpeed fastForwardSpeed, TurboSpeed turboSpeed, bool stretch, bool showBorder, bool showDebugOverlay, LogLevel logLevel,@JsonKey(fromJson: openToolsFromJson) Set<EmulatorTool> openTools, Scaling scaling, bool autoSave, int? autoSaveInterval, bool autoLoad,@JsonKey(fromJson: bindingsFromJson) List<Binding> bindings, int bindingsVersion,@JsonKey(fromJson: gamepadSlotsFromJson, toJson: gamepadSlotsToJson) Map<int, GamepadDeviceKey> gamepadSlots,@JsonKey(fromJson: _lastRomPathFromJson) FilesystemFile? lastRomPath, List<String> recentRomPaths,@JsonKey(fromJson: _recentRomsFromJson) List<RomInfo> recentRoms, bool showTouchControls,@JsonKey(fromJson: narrowTouchInputConfigsFromJson) List<TouchInputConfig> narrowTouchInputConfig,@JsonKey(fromJson: wideTouchInputConfigsFromJson) List<TouchInputConfig> wideTouchInputConfig, Map<String, List<Breakpoint>> breakpoints, Map<String, List<Cheat>> cheats, Region? region, ThemeMode themeMode, RendererPreference renderer, bool rewind, PixelAspectRatio pixelAspectRatio, double customPixelAspectRatio, List<VideoFilter> videoFilters,@JsonKey(toJson: _crtFilterToJson, fromJson: _crtFilterFromJson) CrtFilterSettings crtFilter,@JsonKey(toJson: _overscanToJson, fromJson: _overscanFromJson) Overscan overscan, NesPaletteId paletteId,@JsonKey(toJson: _ntscPaletteToJson, fromJson: _ntscPaletteFromJson) NtscPaletteSettings ntscPalette
});


@override $MixerSettingsCopyWith<$Res> get mixer;@override $CrtFilterSettingsCopyWith<$Res> get crtFilter;@override $OverscanCopyWith<$Res> get overscan;@override $NtscPaletteSettingsCopyWith<$Res> get ntscPalette;

}
/// @nodoc
class __$SettingsCopyWithImpl<$Res>
    implements _$SettingsCopyWith<$Res> {
  __$SettingsCopyWithImpl(this._self, this._then);

  final _Settings _self;
  final $Res Function(_Settings) _then;

/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? volume = null,Object? lowPassFilter = null,Object? swapDutyCycles = null,Object? mixer = null,Object? fastForwardSpeed = null,Object? turboSpeed = null,Object? stretch = null,Object? showBorder = null,Object? showDebugOverlay = null,Object? logLevel = null,Object? openTools = null,Object? scaling = null,Object? autoSave = null,Object? autoSaveInterval = freezed,Object? autoLoad = null,Object? bindings = null,Object? bindingsVersion = null,Object? gamepadSlots = null,Object? lastRomPath = freezed,Object? recentRomPaths = null,Object? recentRoms = null,Object? showTouchControls = null,Object? narrowTouchInputConfig = null,Object? wideTouchInputConfig = null,Object? breakpoints = null,Object? cheats = null,Object? region = freezed,Object? themeMode = null,Object? renderer = null,Object? rewind = null,Object? pixelAspectRatio = null,Object? customPixelAspectRatio = null,Object? videoFilters = null,Object? crtFilter = null,Object? overscan = null,Object? paletteId = null,Object? ntscPalette = null,}) {
  return _then(_Settings(
volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,lowPassFilter: null == lowPassFilter ? _self.lowPassFilter : lowPassFilter // ignore: cast_nullable_to_non_nullable
as bool,swapDutyCycles: null == swapDutyCycles ? _self.swapDutyCycles : swapDutyCycles // ignore: cast_nullable_to_non_nullable
as bool,mixer: null == mixer ? _self.mixer : mixer // ignore: cast_nullable_to_non_nullable
as MixerSettings,fastForwardSpeed: null == fastForwardSpeed ? _self.fastForwardSpeed : fastForwardSpeed // ignore: cast_nullable_to_non_nullable
as FastForwardSpeed,turboSpeed: null == turboSpeed ? _self.turboSpeed : turboSpeed // ignore: cast_nullable_to_non_nullable
as TurboSpeed,stretch: null == stretch ? _self.stretch : stretch // ignore: cast_nullable_to_non_nullable
as bool,showBorder: null == showBorder ? _self.showBorder : showBorder // ignore: cast_nullable_to_non_nullable
as bool,showDebugOverlay: null == showDebugOverlay ? _self.showDebugOverlay : showDebugOverlay // ignore: cast_nullable_to_non_nullable
as bool,logLevel: null == logLevel ? _self.logLevel : logLevel // ignore: cast_nullable_to_non_nullable
as LogLevel,openTools: null == openTools ? _self._openTools : openTools // ignore: cast_nullable_to_non_nullable
as Set<EmulatorTool>,scaling: null == scaling ? _self.scaling : scaling // ignore: cast_nullable_to_non_nullable
as Scaling,autoSave: null == autoSave ? _self.autoSave : autoSave // ignore: cast_nullable_to_non_nullable
as bool,autoSaveInterval: freezed == autoSaveInterval ? _self.autoSaveInterval : autoSaveInterval // ignore: cast_nullable_to_non_nullable
as int?,autoLoad: null == autoLoad ? _self.autoLoad : autoLoad // ignore: cast_nullable_to_non_nullable
as bool,bindings: null == bindings ? _self._bindings : bindings // ignore: cast_nullable_to_non_nullable
as List<Binding>,bindingsVersion: null == bindingsVersion ? _self.bindingsVersion : bindingsVersion // ignore: cast_nullable_to_non_nullable
as int,gamepadSlots: null == gamepadSlots ? _self._gamepadSlots : gamepadSlots // ignore: cast_nullable_to_non_nullable
as Map<int, GamepadDeviceKey>,lastRomPath: freezed == lastRomPath ? _self.lastRomPath : lastRomPath // ignore: cast_nullable_to_non_nullable
as FilesystemFile?,recentRomPaths: null == recentRomPaths ? _self._recentRomPaths : recentRomPaths // ignore: cast_nullable_to_non_nullable
as List<String>,recentRoms: null == recentRoms ? _self._recentRoms : recentRoms // ignore: cast_nullable_to_non_nullable
as List<RomInfo>,showTouchControls: null == showTouchControls ? _self.showTouchControls : showTouchControls // ignore: cast_nullable_to_non_nullable
as bool,narrowTouchInputConfig: null == narrowTouchInputConfig ? _self._narrowTouchInputConfig : narrowTouchInputConfig // ignore: cast_nullable_to_non_nullable
as List<TouchInputConfig>,wideTouchInputConfig: null == wideTouchInputConfig ? _self._wideTouchInputConfig : wideTouchInputConfig // ignore: cast_nullable_to_non_nullable
as List<TouchInputConfig>,breakpoints: null == breakpoints ? _self._breakpoints : breakpoints // ignore: cast_nullable_to_non_nullable
as Map<String, List<Breakpoint>>,cheats: null == cheats ? _self._cheats : cheats // ignore: cast_nullable_to_non_nullable
as Map<String, List<Cheat>>,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as Region?,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemeMode,renderer: null == renderer ? _self.renderer : renderer // ignore: cast_nullable_to_non_nullable
as RendererPreference,rewind: null == rewind ? _self.rewind : rewind // ignore: cast_nullable_to_non_nullable
as bool,pixelAspectRatio: null == pixelAspectRatio ? _self.pixelAspectRatio : pixelAspectRatio // ignore: cast_nullable_to_non_nullable
as PixelAspectRatio,customPixelAspectRatio: null == customPixelAspectRatio ? _self.customPixelAspectRatio : customPixelAspectRatio // ignore: cast_nullable_to_non_nullable
as double,videoFilters: null == videoFilters ? _self._videoFilters : videoFilters // ignore: cast_nullable_to_non_nullable
as List<VideoFilter>,crtFilter: null == crtFilter ? _self.crtFilter : crtFilter // ignore: cast_nullable_to_non_nullable
as CrtFilterSettings,overscan: null == overscan ? _self.overscan : overscan // ignore: cast_nullable_to_non_nullable
as Overscan,paletteId: null == paletteId ? _self.paletteId : paletteId // ignore: cast_nullable_to_non_nullable
as NesPaletteId,ntscPalette: null == ntscPalette ? _self.ntscPalette : ntscPalette // ignore: cast_nullable_to_non_nullable
as NtscPaletteSettings,
  ));
}

/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MixerSettingsCopyWith<$Res> get mixer {
  
  return $MixerSettingsCopyWith<$Res>(_self.mixer, (value) {
    return _then(_self.copyWith(mixer: value));
  });
}/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CrtFilterSettingsCopyWith<$Res> get crtFilter {
  
  return $CrtFilterSettingsCopyWith<$Res>(_self.crtFilter, (value) {
    return _then(_self.copyWith(crtFilter: value));
  });
}/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OverscanCopyWith<$Res> get overscan {
  
  return $OverscanCopyWith<$Res>(_self.overscan, (value) {
    return _then(_self.copyWith(overscan: value));
  });
}/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NtscPaletteSettingsCopyWith<$Res> get ntscPalette {
  
  return $NtscPaletteSettingsCopyWith<$Res>(_self.ntscPalette, (value) {
    return _then(_self.copyWith(ntscPalette: value));
  });
}
}

// dart format on
