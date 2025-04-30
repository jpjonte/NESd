// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'binding.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Binding {

 int get index; InputCombination get input; BindingType get type; InputAction get action;
/// Create a copy of Binding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BindingCopyWith<Binding> get copyWith => _$BindingCopyWithImpl<Binding>(this as Binding, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Binding&&(identical(other.index, index) || other.index == index)&&(identical(other.input, input) || other.input == input)&&(identical(other.type, type) || other.type == type)&&(identical(other.action, action) || other.action == action));
}


@override
int get hashCode => Object.hash(runtimeType,index,input,type,action);

@override
String toString() {
  return 'Binding(index: $index, input: $input, type: $type, action: $action)';
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


// dart format on
