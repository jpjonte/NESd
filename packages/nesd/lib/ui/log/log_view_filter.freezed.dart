// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'log_view_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LogViewFilterState {

 Set<LogChannel> get channels; LogLevel get level; String get search;
/// Create a copy of LogViewFilterState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LogViewFilterStateCopyWith<LogViewFilterState> get copyWith => _$LogViewFilterStateCopyWithImpl<LogViewFilterState>(this as LogViewFilterState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogViewFilterState&&const DeepCollectionEquality().equals(other.channels, channels)&&(identical(other.level, level) || other.level == level)&&(identical(other.search, search) || other.search == search));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(channels),level,search);

@override
String toString() {
  return 'LogViewFilterState(channels: $channels, level: $level, search: $search)';
}


}

/// @nodoc
abstract mixin class $LogViewFilterStateCopyWith<$Res>  {
  factory $LogViewFilterStateCopyWith(LogViewFilterState value, $Res Function(LogViewFilterState) _then) = _$LogViewFilterStateCopyWithImpl;
@useResult
$Res call({
 Set<LogChannel> channels, LogLevel level, String search
});




}
/// @nodoc
class _$LogViewFilterStateCopyWithImpl<$Res>
    implements $LogViewFilterStateCopyWith<$Res> {
  _$LogViewFilterStateCopyWithImpl(this._self, this._then);

  final LogViewFilterState _self;
  final $Res Function(LogViewFilterState) _then;

/// Create a copy of LogViewFilterState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? channels = null,Object? level = null,Object? search = null,}) {
  return _then(LogViewFilterState(
channels: null == channels ? _self.channels : channels // ignore: cast_nullable_to_non_nullable
as Set<LogChannel>,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as LogLevel,search: null == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LogViewFilterState].
extension LogViewFilterStatePatterns on LogViewFilterState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LogViewFilterState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LogViewFilterState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LogViewFilterState value)  $default,){
final _that = this;
switch (_that) {
case _LogViewFilterState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LogViewFilterState value)?  $default,){
final _that = this;
switch (_that) {
case _LogViewFilterState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Set<LogChannel> channels,  LogLevel level,  String search)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LogViewFilterState() when $default != null:
return $default(_that.channels,_that.level,_that.search);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Set<LogChannel> channels,  LogLevel level,  String search)  $default,) {final _that = this;
switch (_that) {
case _LogViewFilterState():
return $default(_that.channels,_that.level,_that.search);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Set<LogChannel> channels,  LogLevel level,  String search)?  $default,) {final _that = this;
switch (_that) {
case _LogViewFilterState() when $default != null:
return $default(_that.channels,_that.level,_that.search);case _:
  return null;

}
}

}

/// @nodoc


class _LogViewFilterState implements LogViewFilterState {
  const _LogViewFilterState({required  Set<LogChannel> channels, this.level = LogLevel.debug, this.search = ''}): _channels = channels;
  

 final  Set<LogChannel> _channels;
@override Set<LogChannel> get channels {
  if (_channels is EqualUnmodifiableSetView) return _channels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_channels);
}

@override@JsonKey() final  LogLevel level;
@override@JsonKey() final  String search;

/// Create a copy of LogViewFilterState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LogViewFilterStateCopyWith<_LogViewFilterState> get copyWith => __$LogViewFilterStateCopyWithImpl<_LogViewFilterState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LogViewFilterState&&const DeepCollectionEquality().equals(other._channels, _channels)&&(identical(other.level, level) || other.level == level)&&(identical(other.search, search) || other.search == search));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_channels),level,search);

@override
String toString() {
  return 'LogViewFilterState(channels: $channels, level: $level, search: $search)';
}


}

/// @nodoc
abstract mixin class _$LogViewFilterStateCopyWith<$Res> implements $LogViewFilterStateCopyWith<$Res> {
  factory _$LogViewFilterStateCopyWith(_LogViewFilterState value, $Res Function(_LogViewFilterState) _then) = __$LogViewFilterStateCopyWithImpl;
@override @useResult
$Res call({
 Set<LogChannel> channels, LogLevel level, String search
});




}
/// @nodoc
class __$LogViewFilterStateCopyWithImpl<$Res>
    implements _$LogViewFilterStateCopyWith<$Res> {
  __$LogViewFilterStateCopyWithImpl(this._self, this._then);

  final _LogViewFilterState _self;
  final $Res Function(_LogViewFilterState) _then;

/// Create a copy of LogViewFilterState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? channels = null,Object? level = null,Object? search = null,}) {
  return _then(_LogViewFilterState(
channels: null == channels ? _self._channels : channels // ignore: cast_nullable_to_non_nullable
as Set<LogChannel>,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as LogLevel,search: null == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
