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

 double get volume; bool get stretch; bool get showBorder; bool get showTiles; bool get showCartridgeInfo; bool get showDebugOverlay; bool get showDebugger; Scaling get scaling; bool get autoSave; int? get autoSaveInterval; bool get autoLoad;@JsonKey(fromJson: bindingsFromJson) List<Binding> get bindings;@JsonKey(fromJson: _lastRomPathFromJson) FilesystemFile? get lastRomPath; List<String> get recentRomPaths;@JsonKey(fromJson: _recentRomsFromJson) List<RomInfo> get recentRoms; bool get showTouchControls;@JsonKey(fromJson: narrowTouchInputConfigsFromJson) List<TouchInputConfig> get narrowTouchInputConfig;@JsonKey(fromJson: wideTouchInputConfigsFromJson) List<TouchInputConfig> get wideTouchInputConfig; Map<String, List<Breakpoint>> get breakpoints; Region? get region; ThemeMode get themeMode;
/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsCopyWith<Settings> get copyWith => _$SettingsCopyWithImpl<Settings>(this as Settings, _$identity);

  /// Serializes this Settings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Settings&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.stretch, stretch) || other.stretch == stretch)&&(identical(other.showBorder, showBorder) || other.showBorder == showBorder)&&(identical(other.showTiles, showTiles) || other.showTiles == showTiles)&&(identical(other.showCartridgeInfo, showCartridgeInfo) || other.showCartridgeInfo == showCartridgeInfo)&&(identical(other.showDebugOverlay, showDebugOverlay) || other.showDebugOverlay == showDebugOverlay)&&(identical(other.showDebugger, showDebugger) || other.showDebugger == showDebugger)&&(identical(other.scaling, scaling) || other.scaling == scaling)&&(identical(other.autoSave, autoSave) || other.autoSave == autoSave)&&(identical(other.autoSaveInterval, autoSaveInterval) || other.autoSaveInterval == autoSaveInterval)&&(identical(other.autoLoad, autoLoad) || other.autoLoad == autoLoad)&&const DeepCollectionEquality().equals(other.bindings, bindings)&&(identical(other.lastRomPath, lastRomPath) || other.lastRomPath == lastRomPath)&&const DeepCollectionEquality().equals(other.recentRomPaths, recentRomPaths)&&const DeepCollectionEquality().equals(other.recentRoms, recentRoms)&&(identical(other.showTouchControls, showTouchControls) || other.showTouchControls == showTouchControls)&&const DeepCollectionEquality().equals(other.narrowTouchInputConfig, narrowTouchInputConfig)&&const DeepCollectionEquality().equals(other.wideTouchInputConfig, wideTouchInputConfig)&&const DeepCollectionEquality().equals(other.breakpoints, breakpoints)&&(identical(other.region, region) || other.region == region)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,volume,stretch,showBorder,showTiles,showCartridgeInfo,showDebugOverlay,showDebugger,scaling,autoSave,autoSaveInterval,autoLoad,const DeepCollectionEquality().hash(bindings),lastRomPath,const DeepCollectionEquality().hash(recentRomPaths),const DeepCollectionEquality().hash(recentRoms),showTouchControls,const DeepCollectionEquality().hash(narrowTouchInputConfig),const DeepCollectionEquality().hash(wideTouchInputConfig),const DeepCollectionEquality().hash(breakpoints),region,themeMode]);

@override
String toString() {
  return 'Settings(volume: $volume, stretch: $stretch, showBorder: $showBorder, showTiles: $showTiles, showCartridgeInfo: $showCartridgeInfo, showDebugOverlay: $showDebugOverlay, showDebugger: $showDebugger, scaling: $scaling, autoSave: $autoSave, autoSaveInterval: $autoSaveInterval, autoLoad: $autoLoad, bindings: $bindings, lastRomPath: $lastRomPath, recentRomPaths: $recentRomPaths, recentRoms: $recentRoms, showTouchControls: $showTouchControls, narrowTouchInputConfig: $narrowTouchInputConfig, wideTouchInputConfig: $wideTouchInputConfig, breakpoints: $breakpoints, region: $region, themeMode: $themeMode)';
}


}

/// @nodoc
abstract mixin class $SettingsCopyWith<$Res>  {
  factory $SettingsCopyWith(Settings value, $Res Function(Settings) _then) = _$SettingsCopyWithImpl;
@useResult
$Res call({
 double volume, bool stretch, bool showBorder, bool showTiles, bool showCartridgeInfo, bool showDebugOverlay, bool showDebugger, Scaling scaling, bool autoSave, int? autoSaveInterval, bool autoLoad,@JsonKey(fromJson: bindingsFromJson) List<Binding> bindings,@JsonKey(fromJson: _lastRomPathFromJson) FilesystemFile? lastRomPath, List<String> recentRomPaths,@JsonKey(fromJson: _recentRomsFromJson) List<RomInfo> recentRoms, bool showTouchControls,@JsonKey(fromJson: narrowTouchInputConfigsFromJson) List<TouchInputConfig> narrowTouchInputConfig,@JsonKey(fromJson: wideTouchInputConfigsFromJson) List<TouchInputConfig> wideTouchInputConfig, Map<String, List<Breakpoint>> breakpoints, Region? region, ThemeMode themeMode
});




}
/// @nodoc
class _$SettingsCopyWithImpl<$Res>
    implements $SettingsCopyWith<$Res> {
  _$SettingsCopyWithImpl(this._self, this._then);

  final Settings _self;
  final $Res Function(Settings) _then;

/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? volume = null,Object? stretch = null,Object? showBorder = null,Object? showTiles = null,Object? showCartridgeInfo = null,Object? showDebugOverlay = null,Object? showDebugger = null,Object? scaling = null,Object? autoSave = null,Object? autoSaveInterval = freezed,Object? autoLoad = null,Object? bindings = null,Object? lastRomPath = freezed,Object? recentRomPaths = null,Object? recentRoms = null,Object? showTouchControls = null,Object? narrowTouchInputConfig = null,Object? wideTouchInputConfig = null,Object? breakpoints = null,Object? region = freezed,Object? themeMode = null,}) {
  return _then(_self.copyWith(
volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,stretch: null == stretch ? _self.stretch : stretch // ignore: cast_nullable_to_non_nullable
as bool,showBorder: null == showBorder ? _self.showBorder : showBorder // ignore: cast_nullable_to_non_nullable
as bool,showTiles: null == showTiles ? _self.showTiles : showTiles // ignore: cast_nullable_to_non_nullable
as bool,showCartridgeInfo: null == showCartridgeInfo ? _self.showCartridgeInfo : showCartridgeInfo // ignore: cast_nullable_to_non_nullable
as bool,showDebugOverlay: null == showDebugOverlay ? _self.showDebugOverlay : showDebugOverlay // ignore: cast_nullable_to_non_nullable
as bool,showDebugger: null == showDebugger ? _self.showDebugger : showDebugger // ignore: cast_nullable_to_non_nullable
as bool,scaling: null == scaling ? _self.scaling : scaling // ignore: cast_nullable_to_non_nullable
as Scaling,autoSave: null == autoSave ? _self.autoSave : autoSave // ignore: cast_nullable_to_non_nullable
as bool,autoSaveInterval: freezed == autoSaveInterval ? _self.autoSaveInterval : autoSaveInterval // ignore: cast_nullable_to_non_nullable
as int?,autoLoad: null == autoLoad ? _self.autoLoad : autoLoad // ignore: cast_nullable_to_non_nullable
as bool,bindings: null == bindings ? _self.bindings : bindings // ignore: cast_nullable_to_non_nullable
as List<Binding>,lastRomPath: freezed == lastRomPath ? _self.lastRomPath : lastRomPath // ignore: cast_nullable_to_non_nullable
as FilesystemFile?,recentRomPaths: null == recentRomPaths ? _self.recentRomPaths : recentRomPaths // ignore: cast_nullable_to_non_nullable
as List<String>,recentRoms: null == recentRoms ? _self.recentRoms : recentRoms // ignore: cast_nullable_to_non_nullable
as List<RomInfo>,showTouchControls: null == showTouchControls ? _self.showTouchControls : showTouchControls // ignore: cast_nullable_to_non_nullable
as bool,narrowTouchInputConfig: null == narrowTouchInputConfig ? _self.narrowTouchInputConfig : narrowTouchInputConfig // ignore: cast_nullable_to_non_nullable
as List<TouchInputConfig>,wideTouchInputConfig: null == wideTouchInputConfig ? _self.wideTouchInputConfig : wideTouchInputConfig // ignore: cast_nullable_to_non_nullable
as List<TouchInputConfig>,breakpoints: null == breakpoints ? _self.breakpoints : breakpoints // ignore: cast_nullable_to_non_nullable
as Map<String, List<Breakpoint>>,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as Region?,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemeMode,
  ));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double volume,  bool stretch,  bool showBorder,  bool showTiles,  bool showCartridgeInfo,  bool showDebugOverlay,  bool showDebugger,  Scaling scaling,  bool autoSave,  int? autoSaveInterval,  bool autoLoad, @JsonKey(fromJson: bindingsFromJson)  List<Binding> bindings, @JsonKey(fromJson: _lastRomPathFromJson)  FilesystemFile? lastRomPath,  List<String> recentRomPaths, @JsonKey(fromJson: _recentRomsFromJson)  List<RomInfo> recentRoms,  bool showTouchControls, @JsonKey(fromJson: narrowTouchInputConfigsFromJson)  List<TouchInputConfig> narrowTouchInputConfig, @JsonKey(fromJson: wideTouchInputConfigsFromJson)  List<TouchInputConfig> wideTouchInputConfig,  Map<String, List<Breakpoint>> breakpoints,  Region? region,  ThemeMode themeMode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Settings() when $default != null:
return $default(_that.volume,_that.stretch,_that.showBorder,_that.showTiles,_that.showCartridgeInfo,_that.showDebugOverlay,_that.showDebugger,_that.scaling,_that.autoSave,_that.autoSaveInterval,_that.autoLoad,_that.bindings,_that.lastRomPath,_that.recentRomPaths,_that.recentRoms,_that.showTouchControls,_that.narrowTouchInputConfig,_that.wideTouchInputConfig,_that.breakpoints,_that.region,_that.themeMode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double volume,  bool stretch,  bool showBorder,  bool showTiles,  bool showCartridgeInfo,  bool showDebugOverlay,  bool showDebugger,  Scaling scaling,  bool autoSave,  int? autoSaveInterval,  bool autoLoad, @JsonKey(fromJson: bindingsFromJson)  List<Binding> bindings, @JsonKey(fromJson: _lastRomPathFromJson)  FilesystemFile? lastRomPath,  List<String> recentRomPaths, @JsonKey(fromJson: _recentRomsFromJson)  List<RomInfo> recentRoms,  bool showTouchControls, @JsonKey(fromJson: narrowTouchInputConfigsFromJson)  List<TouchInputConfig> narrowTouchInputConfig, @JsonKey(fromJson: wideTouchInputConfigsFromJson)  List<TouchInputConfig> wideTouchInputConfig,  Map<String, List<Breakpoint>> breakpoints,  Region? region,  ThemeMode themeMode)  $default,) {final _that = this;
switch (_that) {
case _Settings():
return $default(_that.volume,_that.stretch,_that.showBorder,_that.showTiles,_that.showCartridgeInfo,_that.showDebugOverlay,_that.showDebugger,_that.scaling,_that.autoSave,_that.autoSaveInterval,_that.autoLoad,_that.bindings,_that.lastRomPath,_that.recentRomPaths,_that.recentRoms,_that.showTouchControls,_that.narrowTouchInputConfig,_that.wideTouchInputConfig,_that.breakpoints,_that.region,_that.themeMode);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double volume,  bool stretch,  bool showBorder,  bool showTiles,  bool showCartridgeInfo,  bool showDebugOverlay,  bool showDebugger,  Scaling scaling,  bool autoSave,  int? autoSaveInterval,  bool autoLoad, @JsonKey(fromJson: bindingsFromJson)  List<Binding> bindings, @JsonKey(fromJson: _lastRomPathFromJson)  FilesystemFile? lastRomPath,  List<String> recentRomPaths, @JsonKey(fromJson: _recentRomsFromJson)  List<RomInfo> recentRoms,  bool showTouchControls, @JsonKey(fromJson: narrowTouchInputConfigsFromJson)  List<TouchInputConfig> narrowTouchInputConfig, @JsonKey(fromJson: wideTouchInputConfigsFromJson)  List<TouchInputConfig> wideTouchInputConfig,  Map<String, List<Breakpoint>> breakpoints,  Region? region,  ThemeMode themeMode)?  $default,) {final _that = this;
switch (_that) {
case _Settings() when $default != null:
return $default(_that.volume,_that.stretch,_that.showBorder,_that.showTiles,_that.showCartridgeInfo,_that.showDebugOverlay,_that.showDebugger,_that.scaling,_that.autoSave,_that.autoSaveInterval,_that.autoLoad,_that.bindings,_that.lastRomPath,_that.recentRomPaths,_that.recentRoms,_that.showTouchControls,_that.narrowTouchInputConfig,_that.wideTouchInputConfig,_that.breakpoints,_that.region,_that.themeMode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Settings implements Settings {
   _Settings({this.volume = 1.0, this.stretch = true, this.showBorder = false, this.showTiles = false, this.showCartridgeInfo = false, this.showDebugOverlay = false, this.showDebugger = false, this.scaling = Scaling.autoInteger, this.autoSave = true, this.autoSaveInterval = 1, this.autoLoad = false, @JsonKey(fromJson: bindingsFromJson) final  List<Binding> bindings = const [], @JsonKey(fromJson: _lastRomPathFromJson) this.lastRomPath = null, final  List<String> recentRomPaths = const [], @JsonKey(fromJson: _recentRomsFromJson) final  List<RomInfo> recentRoms = const [], this.showTouchControls = false, @JsonKey(fromJson: narrowTouchInputConfigsFromJson) final  List<TouchInputConfig> narrowTouchInputConfig = const [], @JsonKey(fromJson: wideTouchInputConfigsFromJson) final  List<TouchInputConfig> wideTouchInputConfig = const [], final  Map<String, List<Breakpoint>> breakpoints = const {}, this.region = null, this.themeMode = ThemeMode.system}): _bindings = bindings,_recentRomPaths = recentRomPaths,_recentRoms = recentRoms,_narrowTouchInputConfig = narrowTouchInputConfig,_wideTouchInputConfig = wideTouchInputConfig,_breakpoints = breakpoints;
  factory _Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);

@override@JsonKey() final  double volume;
@override@JsonKey() final  bool stretch;
@override@JsonKey() final  bool showBorder;
@override@JsonKey() final  bool showTiles;
@override@JsonKey() final  bool showCartridgeInfo;
@override@JsonKey() final  bool showDebugOverlay;
@override@JsonKey() final  bool showDebugger;
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

@override@JsonKey() final  Region? region;
@override@JsonKey() final  ThemeMode themeMode;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Settings&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.stretch, stretch) || other.stretch == stretch)&&(identical(other.showBorder, showBorder) || other.showBorder == showBorder)&&(identical(other.showTiles, showTiles) || other.showTiles == showTiles)&&(identical(other.showCartridgeInfo, showCartridgeInfo) || other.showCartridgeInfo == showCartridgeInfo)&&(identical(other.showDebugOverlay, showDebugOverlay) || other.showDebugOverlay == showDebugOverlay)&&(identical(other.showDebugger, showDebugger) || other.showDebugger == showDebugger)&&(identical(other.scaling, scaling) || other.scaling == scaling)&&(identical(other.autoSave, autoSave) || other.autoSave == autoSave)&&(identical(other.autoSaveInterval, autoSaveInterval) || other.autoSaveInterval == autoSaveInterval)&&(identical(other.autoLoad, autoLoad) || other.autoLoad == autoLoad)&&const DeepCollectionEquality().equals(other._bindings, _bindings)&&(identical(other.lastRomPath, lastRomPath) || other.lastRomPath == lastRomPath)&&const DeepCollectionEquality().equals(other._recentRomPaths, _recentRomPaths)&&const DeepCollectionEquality().equals(other._recentRoms, _recentRoms)&&(identical(other.showTouchControls, showTouchControls) || other.showTouchControls == showTouchControls)&&const DeepCollectionEquality().equals(other._narrowTouchInputConfig, _narrowTouchInputConfig)&&const DeepCollectionEquality().equals(other._wideTouchInputConfig, _wideTouchInputConfig)&&const DeepCollectionEquality().equals(other._breakpoints, _breakpoints)&&(identical(other.region, region) || other.region == region)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,volume,stretch,showBorder,showTiles,showCartridgeInfo,showDebugOverlay,showDebugger,scaling,autoSave,autoSaveInterval,autoLoad,const DeepCollectionEquality().hash(_bindings),lastRomPath,const DeepCollectionEquality().hash(_recentRomPaths),const DeepCollectionEquality().hash(_recentRoms),showTouchControls,const DeepCollectionEquality().hash(_narrowTouchInputConfig),const DeepCollectionEquality().hash(_wideTouchInputConfig),const DeepCollectionEquality().hash(_breakpoints),region,themeMode]);

@override
String toString() {
  return 'Settings(volume: $volume, stretch: $stretch, showBorder: $showBorder, showTiles: $showTiles, showCartridgeInfo: $showCartridgeInfo, showDebugOverlay: $showDebugOverlay, showDebugger: $showDebugger, scaling: $scaling, autoSave: $autoSave, autoSaveInterval: $autoSaveInterval, autoLoad: $autoLoad, bindings: $bindings, lastRomPath: $lastRomPath, recentRomPaths: $recentRomPaths, recentRoms: $recentRoms, showTouchControls: $showTouchControls, narrowTouchInputConfig: $narrowTouchInputConfig, wideTouchInputConfig: $wideTouchInputConfig, breakpoints: $breakpoints, region: $region, themeMode: $themeMode)';
}


}

/// @nodoc
abstract mixin class _$SettingsCopyWith<$Res> implements $SettingsCopyWith<$Res> {
  factory _$SettingsCopyWith(_Settings value, $Res Function(_Settings) _then) = __$SettingsCopyWithImpl;
@override @useResult
$Res call({
 double volume, bool stretch, bool showBorder, bool showTiles, bool showCartridgeInfo, bool showDebugOverlay, bool showDebugger, Scaling scaling, bool autoSave, int? autoSaveInterval, bool autoLoad,@JsonKey(fromJson: bindingsFromJson) List<Binding> bindings,@JsonKey(fromJson: _lastRomPathFromJson) FilesystemFile? lastRomPath, List<String> recentRomPaths,@JsonKey(fromJson: _recentRomsFromJson) List<RomInfo> recentRoms, bool showTouchControls,@JsonKey(fromJson: narrowTouchInputConfigsFromJson) List<TouchInputConfig> narrowTouchInputConfig,@JsonKey(fromJson: wideTouchInputConfigsFromJson) List<TouchInputConfig> wideTouchInputConfig, Map<String, List<Breakpoint>> breakpoints, Region? region, ThemeMode themeMode
});




}
/// @nodoc
class __$SettingsCopyWithImpl<$Res>
    implements _$SettingsCopyWith<$Res> {
  __$SettingsCopyWithImpl(this._self, this._then);

  final _Settings _self;
  final $Res Function(_Settings) _then;

/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? volume = null,Object? stretch = null,Object? showBorder = null,Object? showTiles = null,Object? showCartridgeInfo = null,Object? showDebugOverlay = null,Object? showDebugger = null,Object? scaling = null,Object? autoSave = null,Object? autoSaveInterval = freezed,Object? autoLoad = null,Object? bindings = null,Object? lastRomPath = freezed,Object? recentRomPaths = null,Object? recentRoms = null,Object? showTouchControls = null,Object? narrowTouchInputConfig = null,Object? wideTouchInputConfig = null,Object? breakpoints = null,Object? region = freezed,Object? themeMode = null,}) {
  return _then(_Settings(
volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,stretch: null == stretch ? _self.stretch : stretch // ignore: cast_nullable_to_non_nullable
as bool,showBorder: null == showBorder ? _self.showBorder : showBorder // ignore: cast_nullable_to_non_nullable
as bool,showTiles: null == showTiles ? _self.showTiles : showTiles // ignore: cast_nullable_to_non_nullable
as bool,showCartridgeInfo: null == showCartridgeInfo ? _self.showCartridgeInfo : showCartridgeInfo // ignore: cast_nullable_to_non_nullable
as bool,showDebugOverlay: null == showDebugOverlay ? _self.showDebugOverlay : showDebugOverlay // ignore: cast_nullable_to_non_nullable
as bool,showDebugger: null == showDebugger ? _self.showDebugger : showDebugger // ignore: cast_nullable_to_non_nullable
as bool,scaling: null == scaling ? _self.scaling : scaling // ignore: cast_nullable_to_non_nullable
as Scaling,autoSave: null == autoSave ? _self.autoSave : autoSave // ignore: cast_nullable_to_non_nullable
as bool,autoSaveInterval: freezed == autoSaveInterval ? _self.autoSaveInterval : autoSaveInterval // ignore: cast_nullable_to_non_nullable
as int?,autoLoad: null == autoLoad ? _self.autoLoad : autoLoad // ignore: cast_nullable_to_non_nullable
as bool,bindings: null == bindings ? _self._bindings : bindings // ignore: cast_nullable_to_non_nullable
as List<Binding>,lastRomPath: freezed == lastRomPath ? _self.lastRomPath : lastRomPath // ignore: cast_nullable_to_non_nullable
as FilesystemFile?,recentRomPaths: null == recentRomPaths ? _self._recentRomPaths : recentRomPaths // ignore: cast_nullable_to_non_nullable
as List<String>,recentRoms: null == recentRoms ? _self._recentRoms : recentRoms // ignore: cast_nullable_to_non_nullable
as List<RomInfo>,showTouchControls: null == showTouchControls ? _self.showTouchControls : showTouchControls // ignore: cast_nullable_to_non_nullable
as bool,narrowTouchInputConfig: null == narrowTouchInputConfig ? _self._narrowTouchInputConfig : narrowTouchInputConfig // ignore: cast_nullable_to_non_nullable
as List<TouchInputConfig>,wideTouchInputConfig: null == wideTouchInputConfig ? _self._wideTouchInputConfig : wideTouchInputConfig // ignore: cast_nullable_to_non_nullable
as List<TouchInputConfig>,breakpoints: null == breakpoints ? _self._breakpoints : breakpoints // ignore: cast_nullable_to_non_nullable
as Map<String, List<Breakpoint>>,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as Region?,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemeMode,
  ));
}


}

// dart format on
