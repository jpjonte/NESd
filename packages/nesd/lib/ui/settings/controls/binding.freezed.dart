// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'binding.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Binding {


/// Create a copy of Binding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BindingCopyWith<Binding> get copyWith => _$BindingCopyWithImpl<Binding>(this as Binding, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Binding;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Binding&&(identical(other.index, _this.index) || other.index == _this.index)&&(identical(other.input, _this.input) || other.input == _this.input)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.action, _this.action) || other.action == _this.action));
}


@override
int get hashCode {
  final _this = this as Binding;
  return Object.hash(runtimeType,_this.index,_this.input,_this.type,_this.action);
}

@override
String toString() {
  final _this = this as Binding;
  return 'Binding(index: ${_this.index}, input: ${_this.input}, type: ${_this.type}, action: ${_this.action})';
}


}

/// @nodoc
abstract mixin class $BindingCopyWith<$Res>  {
  factory $BindingCopyWith(Binding value, $Res Function(Binding) _then) = _$BindingCopyWithImpl;
@useResult
$Res call({
 int index, InputCombination input, InputAction action, BindingType type
});




}
/// @nodoc
class _$BindingCopyWithImpl<$Res>
    implements $BindingCopyWith<$Res> {
  _$BindingCopyWithImpl(this._self, this._then);

  final Binding _self;
  final $Res Function(Binding) _then;

/// Create a copy of Binding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? input = null,Object? action = null,Object? type = null,}) {
  return _then(Binding(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,input: null == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as InputCombination,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as InputAction,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BindingType,
  ));
}

}


/// Adds pattern-matching-related methods to [Binding].
extension BindingPatterns on Binding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}

// dart format on
