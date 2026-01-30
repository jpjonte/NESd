// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'touch_editor_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TouchEditorState {

 bool get showHint; int? get editingIndex; Orientation? get editingOrientation; TouchInputConfig? get editingConfig;
/// Create a copy of TouchEditorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TouchEditorStateCopyWith<TouchEditorState> get copyWith => _$TouchEditorStateCopyWithImpl<TouchEditorState>(this as TouchEditorState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TouchEditorState&&(identical(other.showHint, showHint) || other.showHint == showHint)&&(identical(other.editingIndex, editingIndex) || other.editingIndex == editingIndex)&&(identical(other.editingOrientation, editingOrientation) || other.editingOrientation == editingOrientation)&&(identical(other.editingConfig, editingConfig) || other.editingConfig == editingConfig));
}


@override
int get hashCode => Object.hash(runtimeType,showHint,editingIndex,editingOrientation,editingConfig);

@override
String toString() {
  return 'TouchEditorState(showHint: $showHint, editingIndex: $editingIndex, editingOrientation: $editingOrientation, editingConfig: $editingConfig)';
}


}

/// @nodoc
abstract mixin class $TouchEditorStateCopyWith<$Res>  {
  factory $TouchEditorStateCopyWith(TouchEditorState value, $Res Function(TouchEditorState) _then) = _$TouchEditorStateCopyWithImpl;
@useResult
$Res call({
 bool showHint, int? editingIndex, Orientation? editingOrientation, TouchInputConfig? editingConfig
});


$TouchInputConfigCopyWith<$Res>? get editingConfig;

}
/// @nodoc
class _$TouchEditorStateCopyWithImpl<$Res>
    implements $TouchEditorStateCopyWith<$Res> {
  _$TouchEditorStateCopyWithImpl(this._self, this._then);

  final TouchEditorState _self;
  final $Res Function(TouchEditorState) _then;

/// Create a copy of TouchEditorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? showHint = null,Object? editingIndex = freezed,Object? editingOrientation = freezed,Object? editingConfig = freezed,}) {
  return _then(_self.copyWith(
showHint: null == showHint ? _self.showHint : showHint // ignore: cast_nullable_to_non_nullable
as bool,editingIndex: freezed == editingIndex ? _self.editingIndex : editingIndex // ignore: cast_nullable_to_non_nullable
as int?,editingOrientation: freezed == editingOrientation ? _self.editingOrientation : editingOrientation // ignore: cast_nullable_to_non_nullable
as Orientation?,editingConfig: freezed == editingConfig ? _self.editingConfig : editingConfig // ignore: cast_nullable_to_non_nullable
as TouchInputConfig?,
  ));
}
/// Create a copy of TouchEditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TouchInputConfigCopyWith<$Res>? get editingConfig {
    if (_self.editingConfig == null) {
    return null;
  }

  return $TouchInputConfigCopyWith<$Res>(_self.editingConfig!, (value) {
    return _then(_self.copyWith(editingConfig: value));
  });
}
}


/// Adds pattern-matching-related methods to [TouchEditorState].
extension TouchEditorStatePatterns on TouchEditorState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TouchEditorState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TouchEditorState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TouchEditorState value)  $default,){
final _that = this;
switch (_that) {
case _TouchEditorState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TouchEditorState value)?  $default,){
final _that = this;
switch (_that) {
case _TouchEditorState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool showHint,  int? editingIndex,  Orientation? editingOrientation,  TouchInputConfig? editingConfig)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TouchEditorState() when $default != null:
return $default(_that.showHint,_that.editingIndex,_that.editingOrientation,_that.editingConfig);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool showHint,  int? editingIndex,  Orientation? editingOrientation,  TouchInputConfig? editingConfig)  $default,) {final _that = this;
switch (_that) {
case _TouchEditorState():
return $default(_that.showHint,_that.editingIndex,_that.editingOrientation,_that.editingConfig);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool showHint,  int? editingIndex,  Orientation? editingOrientation,  TouchInputConfig? editingConfig)?  $default,) {final _that = this;
switch (_that) {
case _TouchEditorState() when $default != null:
return $default(_that.showHint,_that.editingIndex,_that.editingOrientation,_that.editingConfig);case _:
  return null;

}
}

}

/// @nodoc


class _TouchEditorState implements TouchEditorState {
  const _TouchEditorState({this.showHint = true, this.editingIndex = null, this.editingOrientation = null, this.editingConfig = null});
  

@override@JsonKey() final  bool showHint;
@override@JsonKey() final  int? editingIndex;
@override@JsonKey() final  Orientation? editingOrientation;
@override@JsonKey() final  TouchInputConfig? editingConfig;

/// Create a copy of TouchEditorState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TouchEditorStateCopyWith<_TouchEditorState> get copyWith => __$TouchEditorStateCopyWithImpl<_TouchEditorState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TouchEditorState&&(identical(other.showHint, showHint) || other.showHint == showHint)&&(identical(other.editingIndex, editingIndex) || other.editingIndex == editingIndex)&&(identical(other.editingOrientation, editingOrientation) || other.editingOrientation == editingOrientation)&&(identical(other.editingConfig, editingConfig) || other.editingConfig == editingConfig));
}


@override
int get hashCode => Object.hash(runtimeType,showHint,editingIndex,editingOrientation,editingConfig);

@override
String toString() {
  return 'TouchEditorState(showHint: $showHint, editingIndex: $editingIndex, editingOrientation: $editingOrientation, editingConfig: $editingConfig)';
}


}

/// @nodoc
abstract mixin class _$TouchEditorStateCopyWith<$Res> implements $TouchEditorStateCopyWith<$Res> {
  factory _$TouchEditorStateCopyWith(_TouchEditorState value, $Res Function(_TouchEditorState) _then) = __$TouchEditorStateCopyWithImpl;
@override @useResult
$Res call({
 bool showHint, int? editingIndex, Orientation? editingOrientation, TouchInputConfig? editingConfig
});


@override $TouchInputConfigCopyWith<$Res>? get editingConfig;

}
/// @nodoc
class __$TouchEditorStateCopyWithImpl<$Res>
    implements _$TouchEditorStateCopyWith<$Res> {
  __$TouchEditorStateCopyWithImpl(this._self, this._then);

  final _TouchEditorState _self;
  final $Res Function(_TouchEditorState) _then;

/// Create a copy of TouchEditorState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? showHint = null,Object? editingIndex = freezed,Object? editingOrientation = freezed,Object? editingConfig = freezed,}) {
  return _then(_TouchEditorState(
showHint: null == showHint ? _self.showHint : showHint // ignore: cast_nullable_to_non_nullable
as bool,editingIndex: freezed == editingIndex ? _self.editingIndex : editingIndex // ignore: cast_nullable_to_non_nullable
as int?,editingOrientation: freezed == editingOrientation ? _self.editingOrientation : editingOrientation // ignore: cast_nullable_to_non_nullable
as Orientation?,editingConfig: freezed == editingConfig ? _self.editingConfig : editingConfig // ignore: cast_nullable_to_non_nullable
as TouchInputConfig?,
  ));
}

/// Create a copy of TouchEditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TouchInputConfigCopyWith<$Res>? get editingConfig {
    if (_self.editingConfig == null) {
    return null;
  }

  return $TouchInputConfigCopyWith<$Res>(_self.editingConfig!, (value) {
    return _then(_self.copyWith(editingConfig: value));
  });
}
}

// dart format on
