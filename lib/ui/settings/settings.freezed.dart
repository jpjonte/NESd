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
  Scaling get scaling => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
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
      Scaling scaling});
}

/// @nodoc
class _$SettingsCopyWithImpl<$Res, $Val extends Settings>
    implements $SettingsCopyWith<$Res> {
  _$SettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? volume = null,
    Object? stretch = null,
    Object? showBorder = null,
    Object? showTiles = null,
    Object? showCartridgeInfo = null,
    Object? scaling = null,
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
      scaling: null == scaling
          ? _value.scaling
          : scaling // ignore: cast_nullable_to_non_nullable
              as Scaling,
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
      Scaling scaling});
}

/// @nodoc
class __$$SettingsImplCopyWithImpl<$Res>
    extends _$SettingsCopyWithImpl<$Res, _$SettingsImpl>
    implements _$$SettingsImplCopyWith<$Res> {
  __$$SettingsImplCopyWithImpl(
      _$SettingsImpl _value, $Res Function(_$SettingsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? volume = null,
    Object? stretch = null,
    Object? showBorder = null,
    Object? showTiles = null,
    Object? showCartridgeInfo = null,
    Object? scaling = null,
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
      scaling: null == scaling
          ? _value.scaling
          : scaling // ignore: cast_nullable_to_non_nullable
              as Scaling,
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
      this.scaling = Scaling.autoInteger});

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
  final Scaling scaling;

  @override
  String toString() {
    return 'Settings(volume: $volume, stretch: $stretch, showBorder: $showBorder, showTiles: $showTiles, showCartridgeInfo: $showCartridgeInfo, scaling: $scaling)';
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
            (identical(other.scaling, scaling) || other.scaling == scaling));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, volume, stretch, showBorder,
      showTiles, showCartridgeInfo, scaling);

  @JsonKey(ignore: true)
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
      final Scaling scaling}) = _$SettingsImpl;

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
  Scaling get scaling;
  @override
  @JsonKey(ignore: true)
  _$$SettingsImplCopyWith<_$SettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
