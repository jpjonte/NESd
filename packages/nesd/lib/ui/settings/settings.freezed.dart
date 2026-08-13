// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Settings {

 double get volume; bool get stretch; bool get showBorder; bool get showDebugOverlay;@JsonKey(fromJson: openToolsFromJson) Set<EmulatorTool> get openTools; Scaling get scaling; bool get autoSave; int? get autoSaveInterval; bool get autoLoad;@JsonKey(fromJson: bindingsFromJson) List<Binding> get bindings; int get bindingsVersion;@JsonKey(fromJson: _lastRomPathFromJson) FilesystemFile? get lastRomPath; List<String> get recentRomPaths;@JsonKey(fromJson: _recentRomsFromJson) List<RomInfo> get recentRoms; bool get showTouchControls;@JsonKey(fromJson: narrowTouchInputConfigsFromJson) List<TouchInputConfig> get narrowTouchInputConfig;@JsonKey(fromJson: wideTouchInputConfigsFromJson) List<TouchInputConfig> get wideTouchInputConfig; Map<String, List<Breakpoint>> get breakpoints; Map<String, List<Cheat>> get cheats; Region? get region; ThemeMode get themeMode; RendererPreference get renderer; bool get rewind; PixelAspectRatio get pixelAspectRatio; double get customPixelAspectRatio; VideoFilter get videoFilter;@JsonKey(toJson: _crtFilterToJson, fromJson: _crtFilterFromJson) CrtFilterSettings get crtFilter;
/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsCopyWith<Settings> get copyWith => _$SettingsCopyWithImpl<Settings>(this as Settings, _$identity);

  /// Serializes this Settings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Settings&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.stretch, stretch) || other.stretch == stretch)&&(identical(other.showBorder, showBorder) || other.showBorder == showBorder)&&(identical(other.showDebugOverlay, showDebugOverlay) || other.showDebugOverlay == showDebugOverlay)&&const DeepCollectionEquality().equals(other.openTools, openTools)&&(identical(other.scaling, scaling) || other.scaling == scaling)&&(identical(other.autoSave, autoSave) || other.autoSave == autoSave)&&(identical(other.autoSaveInterval, autoSaveInterval) || other.autoSaveInterval == autoSaveInterval)&&(identical(other.autoLoad, autoLoad) || other.autoLoad == autoLoad)&&const DeepCollectionEquality().equals(other.bindings, bindings)&&(identical(other.bindingsVersion, bindingsVersion) || other.bindingsVersion == bindingsVersion)&&(identical(other.lastRomPath, lastRomPath) || other.lastRomPath == lastRomPath)&&const DeepCollectionEquality().equals(other.recentRomPaths, recentRomPaths)&&const DeepCollectionEquality().equals(other.recentRoms, recentRoms)&&(identical(other.showTouchControls, showTouchControls) || other.showTouchControls == showTouchControls)&&const DeepCollectionEquality().equals(other.narrowTouchInputConfig, narrowTouchInputConfig)&&const DeepCollectionEquality().equals(other.wideTouchInputConfig, wideTouchInputConfig)&&const DeepCollectionEquality().equals(other.breakpoints, breakpoints)&&const DeepCollectionEquality().equals(other.cheats, cheats)&&(identical(other.region, region) || other.region == region)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.renderer, renderer) || other.renderer == renderer)&&(identical(other.rewind, rewind) || other.rewind == rewind)&&(identical(other.pixelAspectRatio, pixelAspectRatio) || other.pixelAspectRatio == pixelAspectRatio)&&(identical(other.customPixelAspectRatio, customPixelAspectRatio) || other.customPixelAspectRatio == customPixelAspectRatio)&&(identical(other.videoFilter, videoFilter) || other.videoFilter == videoFilter)&&(identical(other.crtFilter, crtFilter) || other.crtFilter == crtFilter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,volume,stretch,showBorder,showDebugOverlay,const DeepCollectionEquality().hash(openTools),scaling,autoSave,autoSaveInterval,autoLoad,const DeepCollectionEquality().hash(bindings),bindingsVersion,lastRomPath,const DeepCollectionEquality().hash(recentRomPaths),const DeepCollectionEquality().hash(recentRoms),showTouchControls,const DeepCollectionEquality().hash(narrowTouchInputConfig),const DeepCollectionEquality().hash(wideTouchInputConfig),const DeepCollectionEquality().hash(breakpoints),const DeepCollectionEquality().hash(cheats),region,themeMode,renderer,rewind,pixelAspectRatio,customPixelAspectRatio,videoFilter,crtFilter]);

@override
String toString() {
  return 'Settings(volume: $volume, stretch: $stretch, showBorder: $showBorder, showDebugOverlay: $showDebugOverlay, openTools: $openTools, scaling: $scaling, autoSave: $autoSave, autoSaveInterval: $autoSaveInterval, autoLoad: $autoLoad, bindings: $bindings, bindingsVersion: $bindingsVersion, lastRomPath: $lastRomPath, recentRomPaths: $recentRomPaths, recentRoms: $recentRoms, showTouchControls: $showTouchControls, narrowTouchInputConfig: $narrowTouchInputConfig, wideTouchInputConfig: $wideTouchInputConfig, breakpoints: $breakpoints, cheats: $cheats, region: $region, themeMode: $themeMode, renderer: $renderer, rewind: $rewind, pixelAspectRatio: $pixelAspectRatio, customPixelAspectRatio: $customPixelAspectRatio, videoFilter: $videoFilter, crtFilter: $crtFilter)';
}


}

/// @nodoc
abstract mixin class $SettingsCopyWith<$Res>  {
  factory $SettingsCopyWith(Settings value, $Res Function(Settings) _then) = _$SettingsCopyWithImpl;
@useResult
$Res call({
 double volume, bool stretch, bool showBorder, bool showDebugOverlay,@JsonKey(fromJson: openToolsFromJson) Set<EmulatorTool> openTools, Scaling scaling, bool autoSave, int? autoSaveInterval, bool autoLoad,@JsonKey(fromJson: bindingsFromJson) List<Binding> bindings, int bindingsVersion,@JsonKey(fromJson: _lastRomPathFromJson) FilesystemFile? lastRomPath, List<String> recentRomPaths,@JsonKey(fromJson: _recentRomsFromJson) List<RomInfo> recentRoms, bool showTouchControls,@JsonKey(fromJson: narrowTouchInputConfigsFromJson) List<TouchInputConfig> narrowTouchInputConfig,@JsonKey(fromJson: wideTouchInputConfigsFromJson) List<TouchInputConfig> wideTouchInputConfig, Map<String, List<Breakpoint>> breakpoints, Map<String, List<Cheat>> cheats, Region? region, ThemeMode themeMode, RendererPreference renderer, bool rewind, PixelAspectRatio pixelAspectRatio, double customPixelAspectRatio, VideoFilter videoFilter,@JsonKey(toJson: _crtFilterToJson, fromJson: _crtFilterFromJson) CrtFilterSettings crtFilter
});


$CrtFilterSettingsCopyWith<$Res> get crtFilter;

}
/// @nodoc
class _$SettingsCopyWithImpl<$Res>
    implements $SettingsCopyWith<$Res> {
  _$SettingsCopyWithImpl(this._self, this._then);

  final Settings _self;
  final $Res Function(Settings) _then;

/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? volume = null,Object? stretch = null,Object? showBorder = null,Object? showDebugOverlay = null,Object? openTools = null,Object? scaling = null,Object? autoSave = null,Object? autoSaveInterval = freezed,Object? autoLoad = null,Object? bindings = null,Object? bindingsVersion = null,Object? lastRomPath = freezed,Object? recentRomPaths = null,Object? recentRoms = null,Object? showTouchControls = null,Object? narrowTouchInputConfig = null,Object? wideTouchInputConfig = null,Object? breakpoints = null,Object? cheats = null,Object? region = freezed,Object? themeMode = null,Object? renderer = null,Object? rewind = null,Object? pixelAspectRatio = null,Object? customPixelAspectRatio = null,Object? videoFilter = null,Object? crtFilter = null,}) {
  return _then(_self.copyWith(
volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,stretch: null == stretch ? _self.stretch : stretch // ignore: cast_nullable_to_non_nullable
as bool,showBorder: null == showBorder ? _self.showBorder : showBorder // ignore: cast_nullable_to_non_nullable
as bool,showDebugOverlay: null == showDebugOverlay ? _self.showDebugOverlay : showDebugOverlay // ignore: cast_nullable_to_non_nullable
as bool,openTools: null == openTools ? _self.openTools : openTools // ignore: cast_nullable_to_non_nullable
as Set<EmulatorTool>,scaling: null == scaling ? _self.scaling : scaling // ignore: cast_nullable_to_non_nullable
as Scaling,autoSave: null == autoSave ? _self.autoSave : autoSave // ignore: cast_nullable_to_non_nullable
as bool,autoSaveInterval: freezed == autoSaveInterval ? _self.autoSaveInterval : autoSaveInterval // ignore: cast_nullable_to_non_nullable
as int?,autoLoad: null == autoLoad ? _self.autoLoad : autoLoad // ignore: cast_nullable_to_non_nullable
as bool,bindings: null == bindings ? _self.bindings : bindings // ignore: cast_nullable_to_non_nullable
as List<Binding>,bindingsVersion: null == bindingsVersion ? _self.bindingsVersion : bindingsVersion // ignore: cast_nullable_to_non_nullable
as int,lastRomPath: freezed == lastRomPath ? _self.lastRomPath : lastRomPath // ignore: cast_nullable_to_non_nullable
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
as double,videoFilter: null == videoFilter ? _self.videoFilter : videoFilter // ignore: cast_nullable_to_non_nullable
as VideoFilter,crtFilter: null == crtFilter ? _self.crtFilter : crtFilter // ignore: cast_nullable_to_non_nullable
as CrtFilterSettings,
  ));
}
/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CrtFilterSettingsCopyWith<$Res> get crtFilter {
  
  return $CrtFilterSettingsCopyWith<$Res>(_self.crtFilter, (value) {
    return _then(_self.copyWith(crtFilter: value));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double volume,  bool stretch,  bool showBorder,  bool showDebugOverlay, @JsonKey(fromJson: openToolsFromJson)  Set<EmulatorTool> openTools,  Scaling scaling,  bool autoSave,  int? autoSaveInterval,  bool autoLoad, @JsonKey(fromJson: bindingsFromJson)  List<Binding> bindings,  int bindingsVersion, @JsonKey(fromJson: _lastRomPathFromJson)  FilesystemFile? lastRomPath,  List<String> recentRomPaths, @JsonKey(fromJson: _recentRomsFromJson)  List<RomInfo> recentRoms,  bool showTouchControls, @JsonKey(fromJson: narrowTouchInputConfigsFromJson)  List<TouchInputConfig> narrowTouchInputConfig, @JsonKey(fromJson: wideTouchInputConfigsFromJson)  List<TouchInputConfig> wideTouchInputConfig,  Map<String, List<Breakpoint>> breakpoints,  Map<String, List<Cheat>> cheats,  Region? region,  ThemeMode themeMode,  RendererPreference renderer,  bool rewind,  PixelAspectRatio pixelAspectRatio,  double customPixelAspectRatio,  VideoFilter videoFilter, @JsonKey(toJson: _crtFilterToJson, fromJson: _crtFilterFromJson)  CrtFilterSettings crtFilter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Settings() when $default != null:
return $default(_that.volume,_that.stretch,_that.showBorder,_that.showDebugOverlay,_that.openTools,_that.scaling,_that.autoSave,_that.autoSaveInterval,_that.autoLoad,_that.bindings,_that.bindingsVersion,_that.lastRomPath,_that.recentRomPaths,_that.recentRoms,_that.showTouchControls,_that.narrowTouchInputConfig,_that.wideTouchInputConfig,_that.breakpoints,_that.cheats,_that.region,_that.themeMode,_that.renderer,_that.rewind,_that.pixelAspectRatio,_that.customPixelAspectRatio,_that.videoFilter,_that.crtFilter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double volume,  bool stretch,  bool showBorder,  bool showDebugOverlay, @JsonKey(fromJson: openToolsFromJson)  Set<EmulatorTool> openTools,  Scaling scaling,  bool autoSave,  int? autoSaveInterval,  bool autoLoad, @JsonKey(fromJson: bindingsFromJson)  List<Binding> bindings,  int bindingsVersion, @JsonKey(fromJson: _lastRomPathFromJson)  FilesystemFile? lastRomPath,  List<String> recentRomPaths, @JsonKey(fromJson: _recentRomsFromJson)  List<RomInfo> recentRoms,  bool showTouchControls, @JsonKey(fromJson: narrowTouchInputConfigsFromJson)  List<TouchInputConfig> narrowTouchInputConfig, @JsonKey(fromJson: wideTouchInputConfigsFromJson)  List<TouchInputConfig> wideTouchInputConfig,  Map<String, List<Breakpoint>> breakpoints,  Map<String, List<Cheat>> cheats,  Region? region,  ThemeMode themeMode,  RendererPreference renderer,  bool rewind,  PixelAspectRatio pixelAspectRatio,  double customPixelAspectRatio,  VideoFilter videoFilter, @JsonKey(toJson: _crtFilterToJson, fromJson: _crtFilterFromJson)  CrtFilterSettings crtFilter)  $default,) {final _that = this;
switch (_that) {
case _Settings():
return $default(_that.volume,_that.stretch,_that.showBorder,_that.showDebugOverlay,_that.openTools,_that.scaling,_that.autoSave,_that.autoSaveInterval,_that.autoLoad,_that.bindings,_that.bindingsVersion,_that.lastRomPath,_that.recentRomPaths,_that.recentRoms,_that.showTouchControls,_that.narrowTouchInputConfig,_that.wideTouchInputConfig,_that.breakpoints,_that.cheats,_that.region,_that.themeMode,_that.renderer,_that.rewind,_that.pixelAspectRatio,_that.customPixelAspectRatio,_that.videoFilter,_that.crtFilter);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double volume,  bool stretch,  bool showBorder,  bool showDebugOverlay, @JsonKey(fromJson: openToolsFromJson)  Set<EmulatorTool> openTools,  Scaling scaling,  bool autoSave,  int? autoSaveInterval,  bool autoLoad, @JsonKey(fromJson: bindingsFromJson)  List<Binding> bindings,  int bindingsVersion, @JsonKey(fromJson: _lastRomPathFromJson)  FilesystemFile? lastRomPath,  List<String> recentRomPaths, @JsonKey(fromJson: _recentRomsFromJson)  List<RomInfo> recentRoms,  bool showTouchControls, @JsonKey(fromJson: narrowTouchInputConfigsFromJson)  List<TouchInputConfig> narrowTouchInputConfig, @JsonKey(fromJson: wideTouchInputConfigsFromJson)  List<TouchInputConfig> wideTouchInputConfig,  Map<String, List<Breakpoint>> breakpoints,  Map<String, List<Cheat>> cheats,  Region? region,  ThemeMode themeMode,  RendererPreference renderer,  bool rewind,  PixelAspectRatio pixelAspectRatio,  double customPixelAspectRatio,  VideoFilter videoFilter, @JsonKey(toJson: _crtFilterToJson, fromJson: _crtFilterFromJson)  CrtFilterSettings crtFilter)?  $default,) {final _that = this;
switch (_that) {
case _Settings() when $default != null:
return $default(_that.volume,_that.stretch,_that.showBorder,_that.showDebugOverlay,_that.openTools,_that.scaling,_that.autoSave,_that.autoSaveInterval,_that.autoLoad,_that.bindings,_that.bindingsVersion,_that.lastRomPath,_that.recentRomPaths,_that.recentRoms,_that.showTouchControls,_that.narrowTouchInputConfig,_that.wideTouchInputConfig,_that.breakpoints,_that.cheats,_that.region,_that.themeMode,_that.renderer,_that.rewind,_that.pixelAspectRatio,_that.customPixelAspectRatio,_that.videoFilter,_that.crtFilter);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Settings implements Settings {
   _Settings({this.volume = 1.0, this.stretch = true, this.showBorder = false, this.showDebugOverlay = false, @JsonKey(fromJson: openToolsFromJson) final  Set<EmulatorTool> openTools = const <EmulatorTool>{}, this.scaling = Scaling.autoInteger, this.autoSave = true, this.autoSaveInterval = 1, this.autoLoad = false, @JsonKey(fromJson: bindingsFromJson) final  List<Binding> bindings = const [], this.bindingsVersion = 2, @JsonKey(fromJson: _lastRomPathFromJson) this.lastRomPath = null, final  List<String> recentRomPaths = const [], @JsonKey(fromJson: _recentRomsFromJson) final  List<RomInfo> recentRoms = const [], this.showTouchControls = false, @JsonKey(fromJson: narrowTouchInputConfigsFromJson) final  List<TouchInputConfig> narrowTouchInputConfig = const [], @JsonKey(fromJson: wideTouchInputConfigsFromJson) final  List<TouchInputConfig> wideTouchInputConfig = const [], final  Map<String, List<Breakpoint>> breakpoints = const {}, final  Map<String, List<Cheat>> cheats = const {}, this.region = null, this.themeMode = ThemeMode.system, this.renderer = RendererPreference.auto, this.rewind = true, this.pixelAspectRatio = PixelAspectRatio.auto, this.customPixelAspectRatio = 1.0, this.videoFilter = VideoFilter.none, @JsonKey(toJson: _crtFilterToJson, fromJson: _crtFilterFromJson) this.crtFilter = const CrtFilterSettings()}): _openTools = openTools,_bindings = bindings,_recentRomPaths = recentRomPaths,_recentRoms = recentRoms,_narrowTouchInputConfig = narrowTouchInputConfig,_wideTouchInputConfig = wideTouchInputConfig,_breakpoints = breakpoints,_cheats = cheats;
  factory _Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);

@override@JsonKey() final  double volume;
@override@JsonKey() final  bool stretch;
@override@JsonKey() final  bool showBorder;
@override@JsonKey() final  bool showDebugOverlay;
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
@override@JsonKey() final  VideoFilter videoFilter;
@override@JsonKey(toJson: _crtFilterToJson, fromJson: _crtFilterFromJson) final  CrtFilterSettings crtFilter;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Settings&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.stretch, stretch) || other.stretch == stretch)&&(identical(other.showBorder, showBorder) || other.showBorder == showBorder)&&(identical(other.showDebugOverlay, showDebugOverlay) || other.showDebugOverlay == showDebugOverlay)&&const DeepCollectionEquality().equals(other._openTools, _openTools)&&(identical(other.scaling, scaling) || other.scaling == scaling)&&(identical(other.autoSave, autoSave) || other.autoSave == autoSave)&&(identical(other.autoSaveInterval, autoSaveInterval) || other.autoSaveInterval == autoSaveInterval)&&(identical(other.autoLoad, autoLoad) || other.autoLoad == autoLoad)&&const DeepCollectionEquality().equals(other._bindings, _bindings)&&(identical(other.bindingsVersion, bindingsVersion) || other.bindingsVersion == bindingsVersion)&&(identical(other.lastRomPath, lastRomPath) || other.lastRomPath == lastRomPath)&&const DeepCollectionEquality().equals(other._recentRomPaths, _recentRomPaths)&&const DeepCollectionEquality().equals(other._recentRoms, _recentRoms)&&(identical(other.showTouchControls, showTouchControls) || other.showTouchControls == showTouchControls)&&const DeepCollectionEquality().equals(other._narrowTouchInputConfig, _narrowTouchInputConfig)&&const DeepCollectionEquality().equals(other._wideTouchInputConfig, _wideTouchInputConfig)&&const DeepCollectionEquality().equals(other._breakpoints, _breakpoints)&&const DeepCollectionEquality().equals(other._cheats, _cheats)&&(identical(other.region, region) || other.region == region)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.renderer, renderer) || other.renderer == renderer)&&(identical(other.rewind, rewind) || other.rewind == rewind)&&(identical(other.pixelAspectRatio, pixelAspectRatio) || other.pixelAspectRatio == pixelAspectRatio)&&(identical(other.customPixelAspectRatio, customPixelAspectRatio) || other.customPixelAspectRatio == customPixelAspectRatio)&&(identical(other.videoFilter, videoFilter) || other.videoFilter == videoFilter)&&(identical(other.crtFilter, crtFilter) || other.crtFilter == crtFilter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,volume,stretch,showBorder,showDebugOverlay,const DeepCollectionEquality().hash(_openTools),scaling,autoSave,autoSaveInterval,autoLoad,const DeepCollectionEquality().hash(_bindings),bindingsVersion,lastRomPath,const DeepCollectionEquality().hash(_recentRomPaths),const DeepCollectionEquality().hash(_recentRoms),showTouchControls,const DeepCollectionEquality().hash(_narrowTouchInputConfig),const DeepCollectionEquality().hash(_wideTouchInputConfig),const DeepCollectionEquality().hash(_breakpoints),const DeepCollectionEquality().hash(_cheats),region,themeMode,renderer,rewind,pixelAspectRatio,customPixelAspectRatio,videoFilter,crtFilter]);

@override
String toString() {
  return 'Settings(volume: $volume, stretch: $stretch, showBorder: $showBorder, showDebugOverlay: $showDebugOverlay, openTools: $openTools, scaling: $scaling, autoSave: $autoSave, autoSaveInterval: $autoSaveInterval, autoLoad: $autoLoad, bindings: $bindings, bindingsVersion: $bindingsVersion, lastRomPath: $lastRomPath, recentRomPaths: $recentRomPaths, recentRoms: $recentRoms, showTouchControls: $showTouchControls, narrowTouchInputConfig: $narrowTouchInputConfig, wideTouchInputConfig: $wideTouchInputConfig, breakpoints: $breakpoints, cheats: $cheats, region: $region, themeMode: $themeMode, renderer: $renderer, rewind: $rewind, pixelAspectRatio: $pixelAspectRatio, customPixelAspectRatio: $customPixelAspectRatio, videoFilter: $videoFilter, crtFilter: $crtFilter)';
}


}

/// @nodoc
abstract mixin class _$SettingsCopyWith<$Res> implements $SettingsCopyWith<$Res> {
  factory _$SettingsCopyWith(_Settings value, $Res Function(_Settings) _then) = __$SettingsCopyWithImpl;
@override @useResult
$Res call({
 double volume, bool stretch, bool showBorder, bool showDebugOverlay,@JsonKey(fromJson: openToolsFromJson) Set<EmulatorTool> openTools, Scaling scaling, bool autoSave, int? autoSaveInterval, bool autoLoad,@JsonKey(fromJson: bindingsFromJson) List<Binding> bindings, int bindingsVersion,@JsonKey(fromJson: _lastRomPathFromJson) FilesystemFile? lastRomPath, List<String> recentRomPaths,@JsonKey(fromJson: _recentRomsFromJson) List<RomInfo> recentRoms, bool showTouchControls,@JsonKey(fromJson: narrowTouchInputConfigsFromJson) List<TouchInputConfig> narrowTouchInputConfig,@JsonKey(fromJson: wideTouchInputConfigsFromJson) List<TouchInputConfig> wideTouchInputConfig, Map<String, List<Breakpoint>> breakpoints, Map<String, List<Cheat>> cheats, Region? region, ThemeMode themeMode, RendererPreference renderer, bool rewind, PixelAspectRatio pixelAspectRatio, double customPixelAspectRatio, VideoFilter videoFilter,@JsonKey(toJson: _crtFilterToJson, fromJson: _crtFilterFromJson) CrtFilterSettings crtFilter
});


@override $CrtFilterSettingsCopyWith<$Res> get crtFilter;

}
/// @nodoc
class __$SettingsCopyWithImpl<$Res>
    implements _$SettingsCopyWith<$Res> {
  __$SettingsCopyWithImpl(this._self, this._then);

  final _Settings _self;
  final $Res Function(_Settings) _then;

/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? volume = null,Object? stretch = null,Object? showBorder = null,Object? showDebugOverlay = null,Object? openTools = null,Object? scaling = null,Object? autoSave = null,Object? autoSaveInterval = freezed,Object? autoLoad = null,Object? bindings = null,Object? bindingsVersion = null,Object? lastRomPath = freezed,Object? recentRomPaths = null,Object? recentRoms = null,Object? showTouchControls = null,Object? narrowTouchInputConfig = null,Object? wideTouchInputConfig = null,Object? breakpoints = null,Object? cheats = null,Object? region = freezed,Object? themeMode = null,Object? renderer = null,Object? rewind = null,Object? pixelAspectRatio = null,Object? customPixelAspectRatio = null,Object? videoFilter = null,Object? crtFilter = null,}) {
  return _then(_Settings(
volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,stretch: null == stretch ? _self.stretch : stretch // ignore: cast_nullable_to_non_nullable
as bool,showBorder: null == showBorder ? _self.showBorder : showBorder // ignore: cast_nullable_to_non_nullable
as bool,showDebugOverlay: null == showDebugOverlay ? _self.showDebugOverlay : showDebugOverlay // ignore: cast_nullable_to_non_nullable
as bool,openTools: null == openTools ? _self._openTools : openTools // ignore: cast_nullable_to_non_nullable
as Set<EmulatorTool>,scaling: null == scaling ? _self.scaling : scaling // ignore: cast_nullable_to_non_nullable
as Scaling,autoSave: null == autoSave ? _self.autoSave : autoSave // ignore: cast_nullable_to_non_nullable
as bool,autoSaveInterval: freezed == autoSaveInterval ? _self.autoSaveInterval : autoSaveInterval // ignore: cast_nullable_to_non_nullable
as int?,autoLoad: null == autoLoad ? _self.autoLoad : autoLoad // ignore: cast_nullable_to_non_nullable
as bool,bindings: null == bindings ? _self._bindings : bindings // ignore: cast_nullable_to_non_nullable
as List<Binding>,bindingsVersion: null == bindingsVersion ? _self.bindingsVersion : bindingsVersion // ignore: cast_nullable_to_non_nullable
as int,lastRomPath: freezed == lastRomPath ? _self.lastRomPath : lastRomPath // ignore: cast_nullable_to_non_nullable
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
as double,videoFilter: null == videoFilter ? _self.videoFilter : videoFilter // ignore: cast_nullable_to_non_nullable
as VideoFilter,crtFilter: null == crtFilter ? _self.crtFilter : crtFilter // ignore: cast_nullable_to_non_nullable
as CrtFilterSettings,
  ));
}

/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CrtFilterSettingsCopyWith<$Res> get crtFilter {
  
  return $CrtFilterSettingsCopyWith<$Res>(_self.crtFilter, (value) {
    return _then(_self.copyWith(crtFilter: value));
  });
}
}

// dart format on
