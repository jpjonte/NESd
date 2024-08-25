// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Settings _$SettingsFromJson(Map<String, dynamic> json) {
  return _Settings.fromJson(json);
}

/// @nodoc
mixin _$Settings {
  double get volume => throw _privateConstructorUsedError;
  bool get stretch => throw _privateConstructorUsedError;
  bool get showBorder => throw _privateConstructorUsedError;
  bool get showTiles => throw _privateConstructorUsedError;
  bool get showCartridgeInfo => throw _privateConstructorUsedError;
  bool get showDebugOverlay => throw _privateConstructorUsedError;
  bool get showDebugger => throw _privateConstructorUsedError;
  Scaling get scaling => throw _privateConstructorUsedError;
  bool get autoSave => throw _privateConstructorUsedError;
  int? get autoSaveInterval => throw _privateConstructorUsedError;
  @JsonKey(fromJson: bindingsFromJson, toJson: bindingsToJson)
  Map<NesAction, List<InputCombination?>> get bindings =>
      throw _privateConstructorUsedError;
  String? get lastRomPath => throw _privateConstructorUsedError;
  List<String> get recentRomPaths => throw _privateConstructorUsedError;
  bool get showTouchControls => throw _privateConstructorUsedError;
  @JsonKey(fromJson: narrowTouchInputConfigsFromJson)
  List<TouchInputConfig> get narrowTouchInputConfig =>
      throw _privateConstructorUsedError;
  @JsonKey(fromJson: wideTouchInputConfigsFromJson)
  List<TouchInputConfig> get wideTouchInputConfig =>
      throw _privateConstructorUsedError;
  Map<String, List<Breakpoint>> get breakpoints =>
      throw _privateConstructorUsedError;

  /// Serializes this Settings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SettingsCopyWith<Settings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SettingsCopyWith<$Res> {
  factory $SettingsCopyWith(Settings value, $Res Function(Settings) then) =
      _$SettingsCopyWithImpl<$Res, Settings>;
  @useResult
  $Res call(
      {double volume,
      bool stretch,
      bool showBorder,
      bool showTiles,
      bool showCartridgeInfo,
      bool showDebugOverlay,
      bool showDebugger,
      Scaling scaling,
      bool autoSave,
      int? autoSaveInterval,
      @JsonKey(fromJson: bindingsFromJson, toJson: bindingsToJson)
      Map<NesAction, List<InputCombination?>> bindings,
      String? lastRomPath,
      List<String> recentRomPaths,
      bool showTouchControls,
      @JsonKey(fromJson: narrowTouchInputConfigsFromJson)
      List<TouchInputConfig> narrowTouchInputConfig,
      @JsonKey(fromJson: wideTouchInputConfigsFromJson)
      List<TouchInputConfig> wideTouchInputConfig,
      Map<String, List<Breakpoint>> breakpoints});
}

/// @nodoc
class _$SettingsCopyWithImpl<$Res, $Val extends Settings>
    implements $SettingsCopyWith<$Res> {
  _$SettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? volume = null,
    Object? stretch = null,
    Object? showBorder = null,
    Object? showTiles = null,
    Object? showCartridgeInfo = null,
    Object? showDebugOverlay = null,
    Object? showDebugger = null,
    Object? scaling = null,
    Object? autoSave = null,
    Object? autoSaveInterval = freezed,
    Object? bindings = null,
    Object? lastRomPath = freezed,
    Object? recentRomPaths = null,
    Object? showTouchControls = null,
    Object? narrowTouchInputConfig = null,
    Object? wideTouchInputConfig = null,
    Object? breakpoints = null,
  }) {
    return _then(_value.copyWith(
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
      stretch: null == stretch
          ? _value.stretch
          : stretch // ignore: cast_nullable_to_non_nullable
              as bool,
      showBorder: null == showBorder
          ? _value.showBorder
          : showBorder // ignore: cast_nullable_to_non_nullable
              as bool,
      showTiles: null == showTiles
          ? _value.showTiles
          : showTiles // ignore: cast_nullable_to_non_nullable
              as bool,
      showCartridgeInfo: null == showCartridgeInfo
          ? _value.showCartridgeInfo
          : showCartridgeInfo // ignore: cast_nullable_to_non_nullable
              as bool,
      showDebugOverlay: null == showDebugOverlay
          ? _value.showDebugOverlay
          : showDebugOverlay // ignore: cast_nullable_to_non_nullable
              as bool,
      showDebugger: null == showDebugger
          ? _value.showDebugger
          : showDebugger // ignore: cast_nullable_to_non_nullable
              as bool,
      scaling: null == scaling
          ? _value.scaling
          : scaling // ignore: cast_nullable_to_non_nullable
              as Scaling,
      autoSave: null == autoSave
          ? _value.autoSave
          : autoSave // ignore: cast_nullable_to_non_nullable
              as bool,
      autoSaveInterval: freezed == autoSaveInterval
          ? _value.autoSaveInterval
          : autoSaveInterval // ignore: cast_nullable_to_non_nullable
              as int?,
      bindings: null == bindings
          ? _value.bindings
          : bindings // ignore: cast_nullable_to_non_nullable
              as Map<NesAction, List<InputCombination?>>,
      lastRomPath: freezed == lastRomPath
          ? _value.lastRomPath
          : lastRomPath // ignore: cast_nullable_to_non_nullable
              as String?,
      recentRomPaths: null == recentRomPaths
          ? _value.recentRomPaths
          : recentRomPaths // ignore: cast_nullable_to_non_nullable
              as List<String>,
      showTouchControls: null == showTouchControls
          ? _value.showTouchControls
          : showTouchControls // ignore: cast_nullable_to_non_nullable
              as bool,
      narrowTouchInputConfig: null == narrowTouchInputConfig
          ? _value.narrowTouchInputConfig
          : narrowTouchInputConfig // ignore: cast_nullable_to_non_nullable
              as List<TouchInputConfig>,
      wideTouchInputConfig: null == wideTouchInputConfig
          ? _value.wideTouchInputConfig
          : wideTouchInputConfig // ignore: cast_nullable_to_non_nullable
              as List<TouchInputConfig>,
      breakpoints: null == breakpoints
          ? _value.breakpoints
          : breakpoints // ignore: cast_nullable_to_non_nullable
              as Map<String, List<Breakpoint>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SettingsImplCopyWith<$Res>
    implements $SettingsCopyWith<$Res> {
  factory _$$SettingsImplCopyWith(
          _$SettingsImpl value, $Res Function(_$SettingsImpl) then) =
      __$$SettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double volume,
      bool stretch,
      bool showBorder,
      bool showTiles,
      bool showCartridgeInfo,
      bool showDebugOverlay,
      bool showDebugger,
      Scaling scaling,
      bool autoSave,
      int? autoSaveInterval,
      @JsonKey(fromJson: bindingsFromJson, toJson: bindingsToJson)
      Map<NesAction, List<InputCombination?>> bindings,
      String? lastRomPath,
      List<String> recentRomPaths,
      bool showTouchControls,
      @JsonKey(fromJson: narrowTouchInputConfigsFromJson)
      List<TouchInputConfig> narrowTouchInputConfig,
      @JsonKey(fromJson: wideTouchInputConfigsFromJson)
      List<TouchInputConfig> wideTouchInputConfig,
      Map<String, List<Breakpoint>> breakpoints});
}

/// @nodoc
class __$$SettingsImplCopyWithImpl<$Res>
    extends _$SettingsCopyWithImpl<$Res, _$SettingsImpl>
    implements _$$SettingsImplCopyWith<$Res> {
  __$$SettingsImplCopyWithImpl(
      _$SettingsImpl _value, $Res Function(_$SettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? volume = null,
    Object? stretch = null,
    Object? showBorder = null,
    Object? showTiles = null,
    Object? showCartridgeInfo = null,
    Object? showDebugOverlay = null,
    Object? showDebugger = null,
    Object? scaling = null,
    Object? autoSave = null,
    Object? autoSaveInterval = freezed,
    Object? bindings = null,
    Object? lastRomPath = freezed,
    Object? recentRomPaths = null,
    Object? showTouchControls = null,
    Object? narrowTouchInputConfig = null,
    Object? wideTouchInputConfig = null,
    Object? breakpoints = null,
  }) {
    return _then(_$SettingsImpl(
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
      stretch: null == stretch
          ? _value.stretch
          : stretch // ignore: cast_nullable_to_non_nullable
              as bool,
      showBorder: null == showBorder
          ? _value.showBorder
          : showBorder // ignore: cast_nullable_to_non_nullable
              as bool,
      showTiles: null == showTiles
          ? _value.showTiles
          : showTiles // ignore: cast_nullable_to_non_nullable
              as bool,
      showCartridgeInfo: null == showCartridgeInfo
          ? _value.showCartridgeInfo
          : showCartridgeInfo // ignore: cast_nullable_to_non_nullable
              as bool,
      showDebugOverlay: null == showDebugOverlay
          ? _value.showDebugOverlay
          : showDebugOverlay // ignore: cast_nullable_to_non_nullable
              as bool,
      showDebugger: null == showDebugger
          ? _value.showDebugger
          : showDebugger // ignore: cast_nullable_to_non_nullable
              as bool,
      scaling: null == scaling
          ? _value.scaling
          : scaling // ignore: cast_nullable_to_non_nullable
              as Scaling,
      autoSave: null == autoSave
          ? _value.autoSave
          : autoSave // ignore: cast_nullable_to_non_nullable
              as bool,
      autoSaveInterval: freezed == autoSaveInterval
          ? _value.autoSaveInterval
          : autoSaveInterval // ignore: cast_nullable_to_non_nullable
              as int?,
      bindings: null == bindings
          ? _value._bindings
          : bindings // ignore: cast_nullable_to_non_nullable
              as Map<NesAction, List<InputCombination?>>,
      lastRomPath: freezed == lastRomPath
          ? _value.lastRomPath
          : lastRomPath // ignore: cast_nullable_to_non_nullable
              as String?,
      recentRomPaths: null == recentRomPaths
          ? _value._recentRomPaths
          : recentRomPaths // ignore: cast_nullable_to_non_nullable
              as List<String>,
      showTouchControls: null == showTouchControls
          ? _value.showTouchControls
          : showTouchControls // ignore: cast_nullable_to_non_nullable
              as bool,
      narrowTouchInputConfig: null == narrowTouchInputConfig
          ? _value._narrowTouchInputConfig
          : narrowTouchInputConfig // ignore: cast_nullable_to_non_nullable
              as List<TouchInputConfig>,
      wideTouchInputConfig: null == wideTouchInputConfig
          ? _value._wideTouchInputConfig
          : wideTouchInputConfig // ignore: cast_nullable_to_non_nullable
              as List<TouchInputConfig>,
      breakpoints: null == breakpoints
          ? _value._breakpoints
          : breakpoints // ignore: cast_nullable_to_non_nullable
              as Map<String, List<Breakpoint>>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SettingsImpl implements _Settings {
  _$SettingsImpl(
      {this.volume = 1.0,
      this.stretch = true,
      this.showBorder = false,
      this.showTiles = false,
      this.showCartridgeInfo = false,
      this.showDebugOverlay = false,
      this.showDebugger = false,
      this.scaling = Scaling.autoInteger,
      this.autoSave = true,
      this.autoSaveInterval = 1,
      @JsonKey(fromJson: bindingsFromJson, toJson: bindingsToJson)
      final Map<NesAction, List<InputCombination?>> bindings = const {},
      this.lastRomPath = null,
      final List<String> recentRomPaths = const [],
      this.showTouchControls = false,
      @JsonKey(fromJson: narrowTouchInputConfigsFromJson)
      final List<TouchInputConfig> narrowTouchInputConfig = const [],
      @JsonKey(fromJson: wideTouchInputConfigsFromJson)
      final List<TouchInputConfig> wideTouchInputConfig = const [],
      final Map<String, List<Breakpoint>> breakpoints = const {}})
      : _bindings = bindings,
        _recentRomPaths = recentRomPaths,
        _narrowTouchInputConfig = narrowTouchInputConfig,
        _wideTouchInputConfig = wideTouchInputConfig,
        _breakpoints = breakpoints;

  factory _$SettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$SettingsImplFromJson(json);

  @override
  @JsonKey()
  final double volume;
  @override
  @JsonKey()
  final bool stretch;
  @override
  @JsonKey()
  final bool showBorder;
  @override
  @JsonKey()
  final bool showTiles;
  @override
  @JsonKey()
  final bool showCartridgeInfo;
  @override
  @JsonKey()
  final bool showDebugOverlay;
  @override
  @JsonKey()
  final bool showDebugger;
  @override
  @JsonKey()
  final Scaling scaling;
  @override
  @JsonKey()
  final bool autoSave;
  @override
  @JsonKey()
  final int? autoSaveInterval;
  final Map<NesAction, List<InputCombination?>> _bindings;
  @override
  @JsonKey(fromJson: bindingsFromJson, toJson: bindingsToJson)
  Map<NesAction, List<InputCombination?>> get bindings {
    if (_bindings is EqualUnmodifiableMapView) return _bindings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_bindings);
  }

  @override
  @JsonKey()
  final String? lastRomPath;
  final List<String> _recentRomPaths;
  @override
  @JsonKey()
  List<String> get recentRomPaths {
    if (_recentRomPaths is EqualUnmodifiableListView) return _recentRomPaths;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recentRomPaths);
  }

  @override
  @JsonKey()
  final bool showTouchControls;
  final List<TouchInputConfig> _narrowTouchInputConfig;
  @override
  @JsonKey(fromJson: narrowTouchInputConfigsFromJson)
  List<TouchInputConfig> get narrowTouchInputConfig {
    if (_narrowTouchInputConfig is EqualUnmodifiableListView)
      return _narrowTouchInputConfig;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_narrowTouchInputConfig);
  }

  final List<TouchInputConfig> _wideTouchInputConfig;
  @override
  @JsonKey(fromJson: wideTouchInputConfigsFromJson)
  List<TouchInputConfig> get wideTouchInputConfig {
    if (_wideTouchInputConfig is EqualUnmodifiableListView)
      return _wideTouchInputConfig;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_wideTouchInputConfig);
  }

  final Map<String, List<Breakpoint>> _breakpoints;
  @override
  @JsonKey()
  Map<String, List<Breakpoint>> get breakpoints {
    if (_breakpoints is EqualUnmodifiableMapView) return _breakpoints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_breakpoints);
  }

  @override
  String toString() {
    return 'Settings(volume: $volume, stretch: $stretch, showBorder: $showBorder, showTiles: $showTiles, showCartridgeInfo: $showCartridgeInfo, showDebugOverlay: $showDebugOverlay, showDebugger: $showDebugger, scaling: $scaling, autoSave: $autoSave, autoSaveInterval: $autoSaveInterval, bindings: $bindings, lastRomPath: $lastRomPath, recentRomPaths: $recentRomPaths, showTouchControls: $showTouchControls, narrowTouchInputConfig: $narrowTouchInputConfig, wideTouchInputConfig: $wideTouchInputConfig, breakpoints: $breakpoints)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SettingsImpl &&
            (identical(other.volume, volume) || other.volume == volume) &&
            (identical(other.stretch, stretch) || other.stretch == stretch) &&
            (identical(other.showBorder, showBorder) ||
                other.showBorder == showBorder) &&
            (identical(other.showTiles, showTiles) ||
                other.showTiles == showTiles) &&
            (identical(other.showCartridgeInfo, showCartridgeInfo) ||
                other.showCartridgeInfo == showCartridgeInfo) &&
            (identical(other.showDebugOverlay, showDebugOverlay) ||
                other.showDebugOverlay == showDebugOverlay) &&
            (identical(other.showDebugger, showDebugger) ||
                other.showDebugger == showDebugger) &&
            (identical(other.scaling, scaling) || other.scaling == scaling) &&
            (identical(other.autoSave, autoSave) ||
                other.autoSave == autoSave) &&
            (identical(other.autoSaveInterval, autoSaveInterval) ||
                other.autoSaveInterval == autoSaveInterval) &&
            const DeepCollectionEquality().equals(other._bindings, _bindings) &&
            (identical(other.lastRomPath, lastRomPath) ||
                other.lastRomPath == lastRomPath) &&
            const DeepCollectionEquality()
                .equals(other._recentRomPaths, _recentRomPaths) &&
            (identical(other.showTouchControls, showTouchControls) ||
                other.showTouchControls == showTouchControls) &&
            const DeepCollectionEquality().equals(
                other._narrowTouchInputConfig, _narrowTouchInputConfig) &&
            const DeepCollectionEquality()
                .equals(other._wideTouchInputConfig, _wideTouchInputConfig) &&
            const DeepCollectionEquality()
                .equals(other._breakpoints, _breakpoints));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      volume,
      stretch,
      showBorder,
      showTiles,
      showCartridgeInfo,
      showDebugOverlay,
      showDebugger,
      scaling,
      autoSave,
      autoSaveInterval,
      const DeepCollectionEquality().hash(_bindings),
      lastRomPath,
      const DeepCollectionEquality().hash(_recentRomPaths),
      showTouchControls,
      const DeepCollectionEquality().hash(_narrowTouchInputConfig),
      const DeepCollectionEquality().hash(_wideTouchInputConfig),
      const DeepCollectionEquality().hash(_breakpoints));

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SettingsImplCopyWith<_$SettingsImpl> get copyWith =>
      __$$SettingsImplCopyWithImpl<_$SettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SettingsImplToJson(
      this,
    );
  }
}

abstract class _Settings implements Settings {
  factory _Settings(
      {final double volume,
      final bool stretch,
      final bool showBorder,
      final bool showTiles,
      final bool showCartridgeInfo,
      final bool showDebugOverlay,
      final bool showDebugger,
      final Scaling scaling,
      final bool autoSave,
      final int? autoSaveInterval,
      @JsonKey(fromJson: bindingsFromJson, toJson: bindingsToJson)
      final Map<NesAction, List<InputCombination?>> bindings,
      final String? lastRomPath,
      final List<String> recentRomPaths,
      final bool showTouchControls,
      @JsonKey(fromJson: narrowTouchInputConfigsFromJson)
      final List<TouchInputConfig> narrowTouchInputConfig,
      @JsonKey(fromJson: wideTouchInputConfigsFromJson)
      final List<TouchInputConfig> wideTouchInputConfig,
      final Map<String, List<Breakpoint>> breakpoints}) = _$SettingsImpl;

  factory _Settings.fromJson(Map<String, dynamic> json) =
      _$SettingsImpl.fromJson;

  @override
  double get volume;
  @override
  bool get stretch;
  @override
  bool get showBorder;
  @override
  bool get showTiles;
  @override
  bool get showCartridgeInfo;
  @override
  bool get showDebugOverlay;
  @override
  bool get showDebugger;
  @override
  Scaling get scaling;
  @override
  bool get autoSave;
  @override
  int? get autoSaveInterval;
  @override
  @JsonKey(fromJson: bindingsFromJson, toJson: bindingsToJson)
  Map<NesAction, List<InputCombination?>> get bindings;
  @override
  String? get lastRomPath;
  @override
  List<String> get recentRomPaths;
  @override
  bool get showTouchControls;
  @override
  @JsonKey(fromJson: narrowTouchInputConfigsFromJson)
  List<TouchInputConfig> get narrowTouchInputConfig;
  @override
  @JsonKey(fromJson: wideTouchInputConfigsFromJson)
  List<TouchInputConfig> get wideTouchInputConfig;
  @override
  Map<String, List<Breakpoint>> get breakpoints;

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SettingsImplCopyWith<_$SettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
