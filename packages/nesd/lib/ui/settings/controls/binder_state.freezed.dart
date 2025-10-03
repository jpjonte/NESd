// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
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


/// Adds pattern-matching-related methods to [BinderState].
extension BinderStatePatterns on BinderState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BinderState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BinderState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BinderState value)  $default,){
final _that = this;
switch (_that) {
case _BinderState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BinderState value)?  $default,){
final _that = this;
switch (_that) {
case _BinderState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool editing,  InputCombination? input)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BinderState() when $default != null:
return $default(_that.editing,_that.input);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool editing,  InputCombination? input)  $default,) {final _that = this;
switch (_that) {
case _BinderState():
return $default(_that.editing,_that.input);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool editing,  InputCombination? input)?  $default,) {final _that = this;
switch (_that) {
case _BinderState() when $default != null:
return $default(_that.editing,_that.input);case _:
  return null;

}
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
