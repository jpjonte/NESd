// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'overscan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Overscan {

 int get top; int get bottom; int get left; int get right;
/// Create a copy of Overscan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OverscanCopyWith<Overscan> get copyWith => _$OverscanCopyWithImpl<Overscan>(this as Overscan, _$identity);

  /// Serializes this Overscan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Overscan&&(identical(other.top, top) || other.top == top)&&(identical(other.bottom, bottom) || other.bottom == bottom)&&(identical(other.left, left) || other.left == left)&&(identical(other.right, right) || other.right == right));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,top,bottom,left,right);

@override
String toString() {
  return 'Overscan(top: $top, bottom: $bottom, left: $left, right: $right)';
}


}

/// @nodoc
abstract mixin class $OverscanCopyWith<$Res>  {
  factory $OverscanCopyWith(Overscan value, $Res Function(Overscan) _then) = _$OverscanCopyWithImpl;
@useResult
$Res call({
 int top, int bottom, int left, int right
});




}
/// @nodoc
class _$OverscanCopyWithImpl<$Res>
    implements $OverscanCopyWith<$Res> {
  _$OverscanCopyWithImpl(this._self, this._then);

  final Overscan _self;
  final $Res Function(Overscan) _then;

/// Create a copy of Overscan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? top = null,Object? bottom = null,Object? left = null,Object? right = null,}) {
  return _then(Overscan(
top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as int,bottom: null == bottom ? _self.bottom : bottom // ignore: cast_nullable_to_non_nullable
as int,left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as int,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Overscan].
extension OverscanPatterns on Overscan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Overscan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Overscan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Overscan value)  $default,){
final _that = this;
switch (_that) {
case _Overscan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Overscan value)?  $default,){
final _that = this;
switch (_that) {
case _Overscan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int top,  int bottom,  int left,  int right)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Overscan() when $default != null:
return $default(_that.top,_that.bottom,_that.left,_that.right);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int top,  int bottom,  int left,  int right)  $default,) {final _that = this;
switch (_that) {
case _Overscan():
return $default(_that.top,_that.bottom,_that.left,_that.right);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int top,  int bottom,  int left,  int right)?  $default,) {final _that = this;
switch (_that) {
case _Overscan() when $default != null:
return $default(_that.top,_that.bottom,_that.left,_that.right);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Overscan extends Overscan {
  const _Overscan({this.top = 8, this.bottom = 8, this.left = 0, this.right = 0}): super._();
  factory _Overscan.fromJson(Map<String, dynamic> json) => _$OverscanFromJson(json);

@override@JsonKey() final  int top;
@override@JsonKey() final  int bottom;
@override@JsonKey() final  int left;
@override@JsonKey() final  int right;

/// Create a copy of Overscan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OverscanCopyWith<_Overscan> get copyWith => __$OverscanCopyWithImpl<_Overscan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OverscanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Overscan&&(identical(other.top, top) || other.top == top)&&(identical(other.bottom, bottom) || other.bottom == bottom)&&(identical(other.left, left) || other.left == left)&&(identical(other.right, right) || other.right == right));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,top,bottom,left,right);

@override
String toString() {
  return 'Overscan(top: $top, bottom: $bottom, left: $left, right: $right)';
}


}

/// @nodoc
abstract mixin class _$OverscanCopyWith<$Res> implements $OverscanCopyWith<$Res> {
  factory _$OverscanCopyWith(_Overscan value, $Res Function(_Overscan) _then) = __$OverscanCopyWithImpl;
@override @useResult
$Res call({
 int top, int bottom, int left, int right
});




}
/// @nodoc
class __$OverscanCopyWithImpl<$Res>
    implements _$OverscanCopyWith<$Res> {
  __$OverscanCopyWithImpl(this._self, this._then);

  final _Overscan _self;
  final $Res Function(_Overscan) _then;

/// Create a copy of Overscan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? top = null,Object? bottom = null,Object? left = null,Object? right = null,}) {
  return _then(_Overscan(
top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as int,bottom: null == bottom ? _self.bottom : bottom // ignore: cast_nullable_to_non_nullable
as int,left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as int,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
