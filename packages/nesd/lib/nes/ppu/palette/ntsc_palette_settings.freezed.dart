// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ntsc_palette_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NtscPaletteSettings {

 double get hue; double get saturation; double get contrast; double get brightness; double get gamma;
/// Create a copy of NtscPaletteSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NtscPaletteSettingsCopyWith<NtscPaletteSettings> get copyWith => _$NtscPaletteSettingsCopyWithImpl<NtscPaletteSettings>(this as NtscPaletteSettings, _$identity);

  /// Serializes this NtscPaletteSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NtscPaletteSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NtscPaletteSettings&&(identical(other.hue, _this.hue) || other.hue == _this.hue)&&(identical(other.saturation, _this.saturation) || other.saturation == _this.saturation)&&(identical(other.contrast, _this.contrast) || other.contrast == _this.contrast)&&(identical(other.brightness, _this.brightness) || other.brightness == _this.brightness)&&(identical(other.gamma, _this.gamma) || other.gamma == _this.gamma));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NtscPaletteSettings;
  return Object.hash(runtimeType,_this.hue,_this.saturation,_this.contrast,_this.brightness,_this.gamma);
}

@override
String toString() {
  final _this = this as NtscPaletteSettings;
  return 'NtscPaletteSettings(hue: ${_this.hue}, saturation: ${_this.saturation}, contrast: ${_this.contrast}, brightness: ${_this.brightness}, gamma: ${_this.gamma})';
}


}

/// @nodoc
abstract mixin class $NtscPaletteSettingsCopyWith<$Res>  {
  factory $NtscPaletteSettingsCopyWith(NtscPaletteSettings value, $Res Function(NtscPaletteSettings) _then) = _$NtscPaletteSettingsCopyWithImpl;
@useResult
$Res call({
 double hue, double saturation, double contrast, double brightness, double gamma
});




}
/// @nodoc
class _$NtscPaletteSettingsCopyWithImpl<$Res>
    implements $NtscPaletteSettingsCopyWith<$Res> {
  _$NtscPaletteSettingsCopyWithImpl(this._self, this._then);

  final NtscPaletteSettings _self;
  final $Res Function(NtscPaletteSettings) _then;

/// Create a copy of NtscPaletteSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hue = null,Object? saturation = null,Object? contrast = null,Object? brightness = null,Object? gamma = null,}) {
  return _then(NtscPaletteSettings(
hue: null == hue ? _self.hue : hue // ignore: cast_nullable_to_non_nullable
as double,saturation: null == saturation ? _self.saturation : saturation // ignore: cast_nullable_to_non_nullable
as double,contrast: null == contrast ? _self.contrast : contrast // ignore: cast_nullable_to_non_nullable
as double,brightness: null == brightness ? _self.brightness : brightness // ignore: cast_nullable_to_non_nullable
as double,gamma: null == gamma ? _self.gamma : gamma // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [NtscPaletteSettings].
extension NtscPaletteSettingsPatterns on NtscPaletteSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NtscPaletteSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NtscPaletteSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NtscPaletteSettings value)  $default,){
final _that = this;
switch (_that) {
case _NtscPaletteSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NtscPaletteSettings value)?  $default,){
final _that = this;
switch (_that) {
case _NtscPaletteSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double hue,  double saturation,  double contrast,  double brightness,  double gamma)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NtscPaletteSettings() when $default != null:
return $default(_that.hue,_that.saturation,_that.contrast,_that.brightness,_that.gamma);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double hue,  double saturation,  double contrast,  double brightness,  double gamma)  $default,) {final _that = this;
switch (_that) {
case _NtscPaletteSettings():
return $default(_that.hue,_that.saturation,_that.contrast,_that.brightness,_that.gamma);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double hue,  double saturation,  double contrast,  double brightness,  double gamma)?  $default,) {final _that = this;
switch (_that) {
case _NtscPaletteSettings() when $default != null:
return $default(_that.hue,_that.saturation,_that.contrast,_that.brightness,_that.gamma);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NtscPaletteSettings implements NtscPaletteSettings {
  const _NtscPaletteSettings({this.hue = 0.0, this.saturation = 1.0, this.contrast = 1.0, this.brightness = 1.0, this.gamma = 1.8});
  factory _NtscPaletteSettings.fromJson(Map<String, dynamic> json) => _$NtscPaletteSettingsFromJson(json);

@override@JsonKey() final  double hue;
@override@JsonKey() final  double saturation;
@override@JsonKey() final  double contrast;
@override@JsonKey() final  double brightness;
@override@JsonKey() final  double gamma;

/// Create a copy of NtscPaletteSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NtscPaletteSettingsCopyWith<_NtscPaletteSettings> get copyWith => __$NtscPaletteSettingsCopyWithImpl<_NtscPaletteSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NtscPaletteSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NtscPaletteSettings&&(identical(other.hue, hue) || other.hue == hue)&&(identical(other.saturation, saturation) || other.saturation == saturation)&&(identical(other.contrast, contrast) || other.contrast == contrast)&&(identical(other.brightness, brightness) || other.brightness == brightness)&&(identical(other.gamma, gamma) || other.gamma == gamma));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,hue,saturation,contrast,brightness,gamma);
}

@override
String toString() {
    return 'NtscPaletteSettings(hue: $hue, saturation: $saturation, contrast: $contrast, brightness: $brightness, gamma: $gamma)';
}


}

/// @nodoc
abstract mixin class _$NtscPaletteSettingsCopyWith<$Res> implements $NtscPaletteSettingsCopyWith<$Res> {
  factory _$NtscPaletteSettingsCopyWith(_NtscPaletteSettings value, $Res Function(_NtscPaletteSettings) _then) = __$NtscPaletteSettingsCopyWithImpl;
@override @useResult
$Res call({
 double hue, double saturation, double contrast, double brightness, double gamma
});




}
/// @nodoc
class __$NtscPaletteSettingsCopyWithImpl<$Res>
    implements _$NtscPaletteSettingsCopyWith<$Res> {
  __$NtscPaletteSettingsCopyWithImpl(this._self, this._then);

  final _NtscPaletteSettings _self;
  final $Res Function(_NtscPaletteSettings) _then;

/// Create a copy of NtscPaletteSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hue = null,Object? saturation = null,Object? contrast = null,Object? brightness = null,Object? gamma = null,}) {
  return _then(_NtscPaletteSettings(
hue: null == hue ? _self.hue : hue // ignore: cast_nullable_to_non_nullable
as double,saturation: null == saturation ? _self.saturation : saturation // ignore: cast_nullable_to_non_nullable
as double,contrast: null == contrast ? _self.contrast : contrast // ignore: cast_nullable_to_non_nullable
as double,brightness: null == brightness ? _self.brightness : brightness // ignore: cast_nullable_to_non_nullable
as double,gamma: null == gamma ? _self.gamma : gamma // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
