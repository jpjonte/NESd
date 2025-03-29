// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
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
