// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mixer_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MixerSettings {

 double get pulse1; double get pulse2; double get triangle; double get noise; double get dmc; double get mmc5; double get namco163;
/// Create a copy of MixerSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MixerSettingsCopyWith<MixerSettings> get copyWith => _$MixerSettingsCopyWithImpl<MixerSettings>(this as MixerSettings, _$identity);

  /// Serializes this MixerSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MixerSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MixerSettings&&(identical(other.pulse1, _this.pulse1) || other.pulse1 == _this.pulse1)&&(identical(other.pulse2, _this.pulse2) || other.pulse2 == _this.pulse2)&&(identical(other.triangle, _this.triangle) || other.triangle == _this.triangle)&&(identical(other.noise, _this.noise) || other.noise == _this.noise)&&(identical(other.dmc, _this.dmc) || other.dmc == _this.dmc)&&(identical(other.mmc5, _this.mmc5) || other.mmc5 == _this.mmc5)&&(identical(other.namco163, _this.namco163) || other.namco163 == _this.namco163));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MixerSettings;
  return Object.hash(runtimeType,_this.pulse1,_this.pulse2,_this.triangle,_this.noise,_this.dmc,_this.mmc5,_this.namco163);
}

@override
String toString() {
  final _this = this as MixerSettings;
  return 'MixerSettings(pulse1: ${_this.pulse1}, pulse2: ${_this.pulse2}, triangle: ${_this.triangle}, noise: ${_this.noise}, dmc: ${_this.dmc}, mmc5: ${_this.mmc5}, namco163: ${_this.namco163})';
}


}

/// @nodoc
abstract mixin class $MixerSettingsCopyWith<$Res>  {
  factory $MixerSettingsCopyWith(MixerSettings value, $Res Function(MixerSettings) _then) = _$MixerSettingsCopyWithImpl;
@useResult
$Res call({
 double pulse1, double pulse2, double triangle, double noise, double dmc, double mmc5, double namco163
});




}
/// @nodoc
class _$MixerSettingsCopyWithImpl<$Res>
    implements $MixerSettingsCopyWith<$Res> {
  _$MixerSettingsCopyWithImpl(this._self, this._then);

  final MixerSettings _self;
  final $Res Function(MixerSettings) _then;

/// Create a copy of MixerSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pulse1 = null,Object? pulse2 = null,Object? triangle = null,Object? noise = null,Object? dmc = null,Object? mmc5 = null,Object? namco163 = null,}) {
  return _then(MixerSettings(
pulse1: null == pulse1 ? _self.pulse1 : pulse1 // ignore: cast_nullable_to_non_nullable
as double,pulse2: null == pulse2 ? _self.pulse2 : pulse2 // ignore: cast_nullable_to_non_nullable
as double,triangle: null == triangle ? _self.triangle : triangle // ignore: cast_nullable_to_non_nullable
as double,noise: null == noise ? _self.noise : noise // ignore: cast_nullable_to_non_nullable
as double,dmc: null == dmc ? _self.dmc : dmc // ignore: cast_nullable_to_non_nullable
as double,mmc5: null == mmc5 ? _self.mmc5 : mmc5 // ignore: cast_nullable_to_non_nullable
as double,namco163: null == namco163 ? _self.namco163 : namco163 // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [MixerSettings].
extension MixerSettingsPatterns on MixerSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MixerSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MixerSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MixerSettings value)  $default,){
final _that = this;
switch (_that) {
case _MixerSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MixerSettings value)?  $default,){
final _that = this;
switch (_that) {
case _MixerSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double pulse1,  double pulse2,  double triangle,  double noise,  double dmc,  double mmc5,  double namco163)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MixerSettings() when $default != null:
return $default(_that.pulse1,_that.pulse2,_that.triangle,_that.noise,_that.dmc,_that.mmc5,_that.namco163);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double pulse1,  double pulse2,  double triangle,  double noise,  double dmc,  double mmc5,  double namco163)  $default,) {final _that = this;
switch (_that) {
case _MixerSettings():
return $default(_that.pulse1,_that.pulse2,_that.triangle,_that.noise,_that.dmc,_that.mmc5,_that.namco163);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double pulse1,  double pulse2,  double triangle,  double noise,  double dmc,  double mmc5,  double namco163)?  $default,) {final _that = this;
switch (_that) {
case _MixerSettings() when $default != null:
return $default(_that.pulse1,_that.pulse2,_that.triangle,_that.noise,_that.dmc,_that.mmc5,_that.namco163);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MixerSettings extends MixerSettings {
  const _MixerSettings({this.pulse1 = 1.0, this.pulse2 = 1.0, this.triangle = 1.0, this.noise = 1.0, this.dmc = 1.0, this.mmc5 = 1.0, this.namco163 = 1.0}): super._();
  factory _MixerSettings.fromJson(Map<String, dynamic> json) => _$MixerSettingsFromJson(json);

@override@JsonKey() final  double pulse1;
@override@JsonKey() final  double pulse2;
@override@JsonKey() final  double triangle;
@override@JsonKey() final  double noise;
@override@JsonKey() final  double dmc;
@override@JsonKey() final  double mmc5;
@override@JsonKey() final  double namco163;

/// Create a copy of MixerSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MixerSettingsCopyWith<_MixerSettings> get copyWith => __$MixerSettingsCopyWithImpl<_MixerSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MixerSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MixerSettings&&(identical(other.pulse1, pulse1) || other.pulse1 == pulse1)&&(identical(other.pulse2, pulse2) || other.pulse2 == pulse2)&&(identical(other.triangle, triangle) || other.triangle == triangle)&&(identical(other.noise, noise) || other.noise == noise)&&(identical(other.dmc, dmc) || other.dmc == dmc)&&(identical(other.mmc5, mmc5) || other.mmc5 == mmc5)&&(identical(other.namco163, namco163) || other.namco163 == namco163));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,pulse1,pulse2,triangle,noise,dmc,mmc5,namco163);
}

@override
String toString() {
    return 'MixerSettings(pulse1: $pulse1, pulse2: $pulse2, triangle: $triangle, noise: $noise, dmc: $dmc, mmc5: $mmc5, namco163: $namco163)';
}


}

/// @nodoc
abstract mixin class _$MixerSettingsCopyWith<$Res> implements $MixerSettingsCopyWith<$Res> {
  factory _$MixerSettingsCopyWith(_MixerSettings value, $Res Function(_MixerSettings) _then) = __$MixerSettingsCopyWithImpl;
@override @useResult
$Res call({
 double pulse1, double pulse2, double triangle, double noise, double dmc, double mmc5, double namco163
});




}
/// @nodoc
class __$MixerSettingsCopyWithImpl<$Res>
    implements _$MixerSettingsCopyWith<$Res> {
  __$MixerSettingsCopyWithImpl(this._self, this._then);

  final _MixerSettings _self;
  final $Res Function(_MixerSettings) _then;

/// Create a copy of MixerSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pulse1 = null,Object? pulse2 = null,Object? triangle = null,Object? noise = null,Object? dmc = null,Object? mmc5 = null,Object? namco163 = null,}) {
  return _then(_MixerSettings(
pulse1: null == pulse1 ? _self.pulse1 : pulse1 // ignore: cast_nullable_to_non_nullable
as double,pulse2: null == pulse2 ? _self.pulse2 : pulse2 // ignore: cast_nullable_to_non_nullable
as double,triangle: null == triangle ? _self.triangle : triangle // ignore: cast_nullable_to_non_nullable
as double,noise: null == noise ? _self.noise : noise // ignore: cast_nullable_to_non_nullable
as double,dmc: null == dmc ? _self.dmc : dmc // ignore: cast_nullable_to_non_nullable
as double,mmc5: null == mmc5 ? _self.mmc5 : mmc5 // ignore: cast_nullable_to_non_nullable
as double,namco163: null == namco163 ? _self.namco163 : namco163 // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
