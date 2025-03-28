// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'debug_overlay.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DebugOverlayState {

 double get frameTime; double get fps; double get sleepBudget; int get frame;
/// Create a copy of DebugOverlayState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DebugOverlayStateCopyWith<DebugOverlayState> get copyWith => _$DebugOverlayStateCopyWithImpl<DebugOverlayState>(this as DebugOverlayState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DebugOverlayState&&(identical(other.frameTime, frameTime) || other.frameTime == frameTime)&&(identical(other.fps, fps) || other.fps == fps)&&(identical(other.sleepBudget, sleepBudget) || other.sleepBudget == sleepBudget)&&(identical(other.frame, frame) || other.frame == frame));
}


@override
int get hashCode => Object.hash(runtimeType,frameTime,fps,sleepBudget,frame);

@override
String toString() {
  return 'DebugOverlayState(frameTime: $frameTime, fps: $fps, sleepBudget: $sleepBudget, frame: $frame)';
}


}

/// @nodoc
abstract mixin class $DebugOverlayStateCopyWith<$Res>  {
  factory $DebugOverlayStateCopyWith(DebugOverlayState value, $Res Function(DebugOverlayState) _then) = _$DebugOverlayStateCopyWithImpl;
@useResult
$Res call({
 double frameTime, double fps, double sleepBudget, int frame
});




}
/// @nodoc
class _$DebugOverlayStateCopyWithImpl<$Res>
    implements $DebugOverlayStateCopyWith<$Res> {
  _$DebugOverlayStateCopyWithImpl(this._self, this._then);

  final DebugOverlayState _self;
  final $Res Function(DebugOverlayState) _then;

/// Create a copy of DebugOverlayState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? frameTime = null,Object? fps = null,Object? sleepBudget = null,Object? frame = null,}) {
  return _then(_self.copyWith(
frameTime: null == frameTime ? _self.frameTime : frameTime // ignore: cast_nullable_to_non_nullable
as double,fps: null == fps ? _self.fps : fps // ignore: cast_nullable_to_non_nullable
as double,sleepBudget: null == sleepBudget ? _self.sleepBudget : sleepBudget // ignore: cast_nullable_to_non_nullable
as double,frame: null == frame ? _self.frame : frame // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// @nodoc


class _DebugOverlayState implements DebugOverlayState {
  const _DebugOverlayState({this.frameTime = 0, this.fps = 0, this.sleepBudget = 0, this.frame = 0});
  

@override@JsonKey() final  double frameTime;
@override@JsonKey() final  double fps;
@override@JsonKey() final  double sleepBudget;
@override@JsonKey() final  int frame;

/// Create a copy of DebugOverlayState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DebugOverlayStateCopyWith<_DebugOverlayState> get copyWith => __$DebugOverlayStateCopyWithImpl<_DebugOverlayState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DebugOverlayState&&(identical(other.frameTime, frameTime) || other.frameTime == frameTime)&&(identical(other.fps, fps) || other.fps == fps)&&(identical(other.sleepBudget, sleepBudget) || other.sleepBudget == sleepBudget)&&(identical(other.frame, frame) || other.frame == frame));
}


@override
int get hashCode => Object.hash(runtimeType,frameTime,fps,sleepBudget,frame);

@override
String toString() {
  return 'DebugOverlayState(frameTime: $frameTime, fps: $fps, sleepBudget: $sleepBudget, frame: $frame)';
}


}

/// @nodoc
abstract mixin class _$DebugOverlayStateCopyWith<$Res> implements $DebugOverlayStateCopyWith<$Res> {
  factory _$DebugOverlayStateCopyWith(_DebugOverlayState value, $Res Function(_DebugOverlayState) _then) = __$DebugOverlayStateCopyWithImpl;
@override @useResult
$Res call({
 double frameTime, double fps, double sleepBudget, int frame
});




}
/// @nodoc
class __$DebugOverlayStateCopyWithImpl<$Res>
    implements _$DebugOverlayStateCopyWith<$Res> {
  __$DebugOverlayStateCopyWithImpl(this._self, this._then);

  final _DebugOverlayState _self;
  final $Res Function(_DebugOverlayState) _then;

/// Create a copy of DebugOverlayState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? frameTime = null,Object? fps = null,Object? sleepBudget = null,Object? frame = null,}) {
  return _then(_DebugOverlayState(
frameTime: null == frameTime ? _self.frameTime : frameTime // ignore: cast_nullable_to_non_nullable
as double,fps: null == fps ? _self.fps : fps // ignore: cast_nullable_to_non_nullable
as double,sleepBudget: null == sleepBudget ? _self.sleepBudget : sleepBudget // ignore: cast_nullable_to_non_nullable
as double,frame: null == frame ? _self.frame : frame // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
