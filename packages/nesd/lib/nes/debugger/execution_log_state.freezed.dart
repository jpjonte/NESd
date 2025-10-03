// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'execution_log_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExecutionLogState {

 bool get enabled; List<ExecutionLogLine> get lines;
/// Create a copy of ExecutionLogState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExecutionLogStateCopyWith<ExecutionLogState> get copyWith => _$ExecutionLogStateCopyWithImpl<ExecutionLogState>(this as ExecutionLogState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExecutionLogState&&(identical(other.enabled, enabled) || other.enabled == enabled)&&const DeepCollectionEquality().equals(other.lines, lines));
}


@override
int get hashCode => Object.hash(runtimeType,enabled,const DeepCollectionEquality().hash(lines));

@override
String toString() {
  return 'ExecutionLogState(enabled: $enabled, lines: $lines)';
}


}

/// @nodoc
abstract mixin class $ExecutionLogStateCopyWith<$Res>  {
  factory $ExecutionLogStateCopyWith(ExecutionLogState value, $Res Function(ExecutionLogState) _then) = _$ExecutionLogStateCopyWithImpl;
@useResult
$Res call({
 bool enabled, List<ExecutionLogLine> lines
});




}
/// @nodoc
class _$ExecutionLogStateCopyWithImpl<$Res>
    implements $ExecutionLogStateCopyWith<$Res> {
  _$ExecutionLogStateCopyWithImpl(this._self, this._then);

  final ExecutionLogState _self;
  final $Res Function(ExecutionLogState) _then;

/// Create a copy of ExecutionLogState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? lines = null,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<ExecutionLogLine>,
  ));
}

}


/// Adds pattern-matching-related methods to [ExecutionLogState].
extension ExecutionLogStatePatterns on ExecutionLogState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExecutionLogState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExecutionLogState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExecutionLogState value)  $default,){
final _that = this;
switch (_that) {
case _ExecutionLogState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExecutionLogState value)?  $default,){
final _that = this;
switch (_that) {
case _ExecutionLogState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  List<ExecutionLogLine> lines)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExecutionLogState() when $default != null:
return $default(_that.enabled,_that.lines);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  List<ExecutionLogLine> lines)  $default,) {final _that = this;
switch (_that) {
case _ExecutionLogState():
return $default(_that.enabled,_that.lines);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  List<ExecutionLogLine> lines)?  $default,) {final _that = this;
switch (_that) {
case _ExecutionLogState() when $default != null:
return $default(_that.enabled,_that.lines);case _:
  return null;

}
}

}

/// @nodoc


class _ExecutionLogState implements ExecutionLogState {
  const _ExecutionLogState({this.enabled = false, final  List<ExecutionLogLine> lines = const []}): _lines = lines;
  

@override@JsonKey() final  bool enabled;
 final  List<ExecutionLogLine> _lines;
@override@JsonKey() List<ExecutionLogLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}


/// Create a copy of ExecutionLogState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExecutionLogStateCopyWith<_ExecutionLogState> get copyWith => __$ExecutionLogStateCopyWithImpl<_ExecutionLogState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExecutionLogState&&(identical(other.enabled, enabled) || other.enabled == enabled)&&const DeepCollectionEquality().equals(other._lines, _lines));
}


@override
int get hashCode => Object.hash(runtimeType,enabled,const DeepCollectionEquality().hash(_lines));

@override
String toString() {
  return 'ExecutionLogState(enabled: $enabled, lines: $lines)';
}


}

/// @nodoc
abstract mixin class _$ExecutionLogStateCopyWith<$Res> implements $ExecutionLogStateCopyWith<$Res> {
  factory _$ExecutionLogStateCopyWith(_ExecutionLogState value, $Res Function(_ExecutionLogState) _then) = __$ExecutionLogStateCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, List<ExecutionLogLine> lines
});




}
/// @nodoc
class __$ExecutionLogStateCopyWithImpl<$Res>
    implements _$ExecutionLogStateCopyWith<$Res> {
  __$ExecutionLogStateCopyWithImpl(this._self, this._then);

  final _ExecutionLogState _self;
  final $Res Function(_ExecutionLogState) _then;

/// Create a copy of ExecutionLogState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? lines = null,}) {
  return _then(_ExecutionLogState(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<ExecutionLogLine>,
  ));
}


}

// dart format on
