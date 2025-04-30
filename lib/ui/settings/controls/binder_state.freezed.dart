// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'binder_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BinderState {

 bool get editing; InputCombination? get input;
/// Create a copy of BinderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BinderStateCopyWith<BinderState> get copyWith => _$BinderStateCopyWithImpl<BinderState>(this as BinderState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BinderState&&(identical(other.editing, editing) || other.editing == editing)&&(identical(other.input, input) || other.input == input));
}


@override
int get hashCode => Object.hash(runtimeType,editing,input);

@override
String toString() {
  return 'BinderState(editing: $editing, input: $input)';
}


}

/// @nodoc
abstract mixin class $BinderStateCopyWith<$Res>  {
  factory $BinderStateCopyWith(BinderState value, $Res Function(BinderState) _then) = _$BinderStateCopyWithImpl;
@useResult
$Res call({
 bool editing, InputCombination? input
});


$InputCombinationCopyWith<$Res>? get input;

}
/// @nodoc
class _$BinderStateCopyWithImpl<$Res>
    implements $BinderStateCopyWith<$Res> {
  _$BinderStateCopyWithImpl(this._self, this._then);

  final BinderState _self;
  final $Res Function(BinderState) _then;

/// Create a copy of BinderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? editing = null,Object? input = freezed,}) {
  return _then(_self.copyWith(
editing: null == editing ? _self.editing : editing // ignore: cast_nullable_to_non_nullable
as bool,input: freezed == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as InputCombination?,
  ));
}
/// Create a copy of BinderState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InputCombinationCopyWith<$Res>? get input {
    if (_self.input == null) {
    return null;
  }

  return $InputCombinationCopyWith<$Res>(_self.input!, (value) {
    return _then(_self.copyWith(input: value));
  });
}
}


/// @nodoc


class _BinderState implements BinderState {
  const _BinderState({this.editing = false, this.input});
  

@override@JsonKey() final  bool editing;
@override final  InputCombination? input;

/// Create a copy of BinderState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BinderStateCopyWith<_BinderState> get copyWith => __$BinderStateCopyWithImpl<_BinderState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BinderState&&(identical(other.editing, editing) || other.editing == editing)&&(identical(other.input, input) || other.input == input));
}


@override
int get hashCode => Object.hash(runtimeType,editing,input);

@override
String toString() {
  return 'BinderState(editing: $editing, input: $input)';
}


}

/// @nodoc
abstract mixin class _$BinderStateCopyWith<$Res> implements $BinderStateCopyWith<$Res> {
  factory _$BinderStateCopyWith(_BinderState value, $Res Function(_BinderState) _then) = __$BinderStateCopyWithImpl;
@override @useResult
$Res call({
 bool editing, InputCombination? input
});


@override $InputCombinationCopyWith<$Res>? get input;

}
/// @nodoc
class __$BinderStateCopyWithImpl<$Res>
    implements _$BinderStateCopyWith<$Res> {
  __$BinderStateCopyWithImpl(this._self, this._then);

  final _BinderState _self;
  final $Res Function(_BinderState) _then;

/// Create a copy of BinderState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? editing = null,Object? input = freezed,}) {
  return _then(_BinderState(
editing: null == editing ? _self.editing : editing // ignore: cast_nullable_to_non_nullable
as bool,input: freezed == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as InputCombination?,
  ));
}

/// Create a copy of BinderState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InputCombinationCopyWith<$Res>? get input {
    if (_self.input == null) {
    return null;
  }

  return $InputCombinationCopyWith<$Res>(_self.input!, (value) {
    return _then(_self.copyWith(input: value));
  });
}
}

// dart format on
